require "heroku/command"
require "tmpdir"
require "rest_client"

# manage buildpacks
#
class Heroku::Command::Buildpacks < Heroku::Command::Base

  # buildpacks:kit
  #
  # list the buildpacks in your kit
  #
  def kit
    styled_header "Buildpacks in #{auth.user}'s kit"
    packs = json_decode(server["/buildkit"].get)
    styled_array packs.map{|b| "#{b['org']}/#{b['name']}" }
  end

  # buildpacks:setup
  #
  # set up the BUILDPACK_URL for an app
  #
  def setup
    action "Modifying BUILDPACK_URL for #{app}" do
      buildpack_url = buildkit_host + "/buildkit/#{auth.user}.tgz"
      api.put_config_vars app, "BUILDPACK_URL" => buildpack_url
    end
  end

  # buildpacks:list
  #
  # list all available buildpacks
  #
  def list
    styled_header "Available Buildpacks"
    packs = json_decode(server["/buildpacks"].get)
    styled_array packs.map{|b| "#{b['org']}/#{b['name']}" }
  end
  alias_method :index, :list

  # buildpacks:add ORG/NAME
  #
  # add a buildpack to your kit
  #
  def add
    name = shift_argument || error("Must specify a buildpack name")
    action("Adding #{name} to your kit") do
      begin
        server["/buildkit/#{name}"].put({})
      rescue RestClient::ResourceNotFound
        error "No such buildpack: #{name}"
      rescue RestClient::Forbidden
        error "The #{name} buildpack is already in your kit"
      end
    end
  end

  # buildpacks:remove ORG/NAME
  #
  # remove a buildpack from your kit
  #
  def remove
    name = shift_argument || error("Must specify a buildpack name")
    action("Removing #{name} from your kit") do
      begin
        server["/buildkit/#{name}"].delete({})
      rescue RestClient::ResourceNotFound
        error "The #{name} buildpack is not in your kit"
      end
    end
  end

  # buildpacks:publish ORG/NAME
  #
  # publish a buildpack.
  #
  # -d, --buildpack-dir DIR # find buildpack in DIR instead of current directory
  #
  def publish
    name = shift_argument || error("Must specify a buildpack name")
    bp_dir = options[:buildpack_dir] || Dir.pwd

    action "Publishing #{name} buildpack" do
      Dir.mktmpdir do |dir|
        %x{ cd #{bp_dir} && tar czf #{dir}/buildpack.tgz * }

        begin
          buildpack = File.open("#{dir}/buildpack.tgz", "rb")
          response = server["/buildpacks/#{name}"].post(:buildpack => buildpack)
          revision = json_decode(response)["revision"]
          status "v#{revision}"
        rescue RestClient::Exception => e
          error json_decode(e.http_body)["message"]
        end
      end
    end
  end

  # buildpacks:rollback ORG/NAME [REVISION]
  #
  # roll back a buildpack
  #
  # If no revision is specified, use previous.
  #
  def rollback
    name = shift_argument || error("Must specify a buildpack name")
    target = shift_argument || "previous"
    target = target.sub(/^v/, "")
    action "Rolling back #{name} buildpack" do
      begin
        response = server["/buildpacks/#{name}/revisions/#{target}"].post({})
        revision = json_decode(response)["revision"]
        target = target == "previous" ? target : "v#{target}"
        status "Rolled back to #{target} as v#{revision}"
      rescue RestClient::BadRequest => e
        error json_decode(e.http_body)["message"]
      rescue RestClient::Forbidden
        error "The '#{name}' buildpack is owned by someone else."
      rescue RestClient::ResourceNotFound
        error "The '#{name}' buildpack does not exist."
      end
    end
  end

  # buildpacks:revisions ORG/NAME
  #
  # list buildpack revisions
  #
  def revisions
    name = shift_argument || error("Must specify a buildpack name")
    begin
      response = server["/buildpacks/#{name}/revisions"].get
      revisions = json_decode(response).reverse.map do |r|
        ["v#{r["id"]}", time_ago((Time.now - Time.parse(r["created_at"])).to_i)]
      end
      styled_header("Revisions")
      styled_array(revisions, :sort => false)
    rescue RestClient::BadRequest => e
      error json_decode(e.http_body)["message"]
    rescue RestClient::Forbidden
      error "The '#{name}' buildpack is owned by someone else."
    rescue RestClient::ResourceNotFound
      error "The '#{name}' buildpack does not exist."
    end
  end

  # buildpacks:share ORG EMAIL
  #
  # Add user with EMAIL as a member of ORG
  #
  def share
    org = shift_argument || error("Must specify an organization name")
    email = shift_argument || error("Must specify a user email address")
    action "Adding #{email} to #{org}" do
      begin
        response = server["/buildpacks/#{org}/share/#{email}"].post({})
      rescue RestClient::BadRequest => e
        error json_decode(e.http_body)["message"]
      rescue RestClient::Forbidden
        error "You do not have access to #{org}."
      rescue RestClient::Conflict
        error "#{email} is already a member of #{org}."
      end
    end
  end

  # buildpacks:unshare ORG EMAIL
  #
  # Remove user with EMAIL from ORG
  #
  def unshare
    org = shift_argument || error("Must specify an organization name")
    email = shift_argument || error("Must specify a user email address")
    action "Removing #{email} from #{org}" do
      begin
        response = server["/buildpacks/#{org}/share/#{email}"].delete
      rescue RestClient::BadRequest => e
        error json_decode(e.http_body)["message"]
      rescue RestClient::Forbidden
        error "You do not have access to #{org}."
      rescue RestClient::ResourceNotFound
        error "#{email} is not a member of #{org}."
      end
    end
  end

  private

  def auth
    Heroku::Auth
  end

  def buildkit_host
    ENV["BUILDPACK_SERVER_URL"] || "https://buildkits.herokuapp.com"
  end

  def server
    RestClient::Resource.new(buildkit_host, :user => auth.user,
                             :password => auth.password)
  end
end

