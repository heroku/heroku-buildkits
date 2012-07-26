require 'minitest/autorun'
require 'fileutils'
require 'open3'
require 'open-uri'
require 'stringio'
require 'tmpdir'
require 'pg'

require 'heroku/api'

BASE_PATH       = File.expand_path(File.join(File.dirname(__FILE__), '..'))
BIN_STDERR_PATH = File.join(BASE_PATH, 'bin', 'stderr')
LIB_PATH        = File.join(BASE_PATH, 'lib')
BIN_HEROKU_PATH = %x{ which heroku }.chomp
RUBY_PATH       = %x{ which ruby }.chomp
RUBY_OPTS       = "-I#{LIB_PATH}"
CHDIR           = Dir.mktmpdir

HOME        = Dir.mktmpdir
PATH        = `echo $PATH`
NETRC_PATH  = File.join(HOME,   '.netrc')

HEROKU_USER     = ENV['HEROKU_USER']
HEROKU_API_KEY  = ENV['HEROKU_API_KEY']

HEROKU_OTHER_USER         = ENV['HEROKU_OTHER_USER']
HEROKU_OTHER_API_KEY = ENV['HEROKU_OTHER_API_KEY']

ENV["BUILDPACK_SERVER_URL"] ||= "http://localhost:5000"

module Heroku
  def self.reset_netrc(user=HEROKU_USER, api_key=HEROKU_API_KEY)
    FileUtils.rm_rf(NETRC_PATH)
    # Setup netrc credentials in HOME
    File.open(NETRC_PATH, 'w') do |netrc|
      netrc.puts(<<-NETRC)
    machine api.heroku.com
      login #{user}
      password #{api_key}
    machine code.heroku.com
      login #{user}
      password #{api_key}
      NETRC
    end
    FileUtils.chmod(0600, NETRC_PATH)
  end
end

Heroku.reset_netrc

class Heroku::Test < MiniTest::Unit::TestCase
  def self.test_order
    :sorted
  end

  def self.commands
    @commands ||= Hash.new {|hash,key| hash[key] = {}}
  end

  def self.current_command
    @current_command
  end

  def self.heroku(command, options={})
    unless File.exists?(File.join(HOME, ".heroku", "plugins"))
      FileUtils.mkdir_p(File.join(HOME, ".heroku", "plugins"))
      %x{ ln -s #{BASE_PATH} #{File.join(HOME, ".heroku", "plugins")} }
      %x{ ln -s #{BASE_PATH}/heroku-anvil #{File.join(HOME, ".heroku", "plugins")} }
    end

    options = {
      :env    => {},
      :stdin  => nil
    }.merge!(options)
    Open3.capture3(
      {
        # Setup BROWSER for opening stuff
        'BROWSER'         => BIN_STDERR_PATH,
        # Setup HOME for config, credentials and plugins
        'HOME'            => HOME,
        # Setup PATH for ruby executable.
        'PATH'            => PATH,
        # Send BASE_PATH through so that the SimpleCov injector can find us.
        'BASE_PATH'       => BASE_PATH,
        # Use local buildkits server.
        "BUILDPACK_SERVER_URL" => ENV["BUILDPACK_SERVER_URL"],
      }.merge(options[:env]),
      "#{RUBY_PATH} #{RUBY_OPTS} #{BIN_HEROKU_PATH} #{command}",
      {
        # Change to an empty directory.
        :chdir            => CHDIR,
        # Set stdin for command.
        :stdin_data       => options[:stdin].to_s,
        # Unset env except for what is explicitly set above.
        :unsetenv_others  => true
      }
    )
  end

  def self.heroku_api
    @heroku_api ||= Heroku::API.new(:api_key => HEROKU_API_KEY)
  end

  def self.heroku_collaborator_api
    @heroku_collaborator_api ||= Heroku::API.new(:api_key => HEROKU_COLLABORATOR_API_KEY)
  end

  def self.after(&block)
    self.commands[@current_command][:after] = block
  end

  def self.before(&block)
    self.commands[@current_command][:before] = block
  end

  def self.status(value=nil, &block)
    if value && block_given?
      raise("status takes either a value or block, not both")
    elsif value
      self.commands[@current_command][:status] = lambda { value }
    else
      self.commands[@current_command][:status] = block
    end
  end

  def self.stderr(value=nil, &block)
    if value && block_given?
      raise("stderr takes either a value or block, not both")
    elsif value
      self.commands[@current_command][:stderr] = lambda { value }
    else
      self.commands[@current_command][:stderr] = block
    end
  end

  def self.stdout(value=nil, &block)
    if value && block_given?
      raise("stdout takes either a value or block, not both")
    elsif value
      self.commands[@current_command][:stdout] = lambda { value }
    else
      self.commands[@current_command][:stdout] = block
    end
  end

  def self.test_heroku(command, options={}, &block)
    @num ? @num = @num.succ : @num = "01" # need ordered tests

    if options[:stdin]
      @current_command = "test #{@num} #{command} <<< #{options[:stdin].inspect}"
    else
      @current_command = "test #{@num} #{command}"
    end
    @current_command = [@current_command, options[:comment]].compact.join(' # ')
    self.commands[@current_command][:command] = command
    self.commands[@current_command][:stdin]   = options[:stdin]
    self.commands[@current_command][:user]    = options[:user]
    self.commands[@current_command][:env]     = options[:env] || {}
    # sane default values for status code and stderr, can be overridden
    self.commands[@current_command][:status]  = lambda { 0 }
    self.commands[@current_command][:stderr]  = lambda { "" }
    yield
    instance_eval(<<-METHOD)
      define_method('#{@current_command}') do
        assert_heroku_output('#{@current_command}')
      end
    METHOD
    @current_command = nil
  end

  # Internal: Assert output for a heroku command.
  #
  # command - The command to be run.
  # stdin   - The value for stdin of command (default: '').
  # block   - The block to run to find expected values, should return some or
  #           all of [stdout, stderr, status] (default: ['', '', 0]).
  #
  # Returns true.
  # Raises if command returns something which fails to match the block.
  def assert_heroku_output(current_command)
    data = self.class.commands[current_command]

    # Run any setup needed before command.
    data[:before] && data[:before].call

    # Use self.class.class_eval(%{"#{x}"}) interpolate in context.
    command = self.class.class_eval(%{"#{data[:command]}"})
    stdin = self.class.class_eval(%{"#{data[:stdin]}"})

    Heroku.reset_netrc(HEROKU_OTHER_USER, HEROKU_OTHER_API_KEY) if data[:user] == :other

    actual = {}
    actual[:stdout], actual[:stderr], actual[:status] = self.class.heroku(
      command, { :env => data[:env] || {}, :stdin => stdin }
    )

    # Run any assertion setup or test cleanup after command.
    data[:after] && data[:after].call

    [:stderr, :stdout, :status].each do |key|
      case expected = data[key].call
      when Integer # status
        assert_equal(expected, actual[key].exitstatus, key)
      when Regexp
        assert_match(expected, actual[key], key)
      when String
        assert_equal(expected, actual[key], key)
      end
    end
  ensure
    Heroku.reset_netrc
  end

  def self.buildpack_dir(name)
    File.join(BASE_PATH, 'test_buildpacks', name)
  end

  def self.buildpack_url(name, org="heroku")
    bucket = ENV['BUILDPACK_BUCKET'] || 'buildkits-dev'
    url = "http://#{bucket}.s3.amazonaws.com/buildpacks/#{org}/#{name}.tgz"
  end

  def self.publish(org, name, dir=buildpack_dir(name))
    "buildpacks:publish #{org}/#{name} -d #{dir}"
  end

  def self.reset_db
    uri = URI.parse(ENV["DATABASE_URL"] || "postgres://localhost/buildkits-test")
    params = {:host => uri.host, :port => uri.port, :dbname => uri.path[1 .. -1]}
    @db ||= PG.connect(params)
    ["buildpacks", "kits", "memberships", "organizations", "revisions"].each do |t|
      @db.exec "DELETE from #{t}"
    end
  end
end

Heroku::Test.reset_db
