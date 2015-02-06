require "heroku/command"
require "tmpdir"
require "rest_client"

# manage buildkits
#
class Heroku::Command::Buildkits < Heroku::Command::Base

  # buildkits:list
  #
  # list all available buildkits
  #
  #Example:
  #
  # $ heroku buildkits:list
  #
  # === Available Buildkits
  # heroku/clojure
  # heroku/emacs
  # heroku/erlang
  # myorg/mypack
  # [...]
  #
  def list
    styled_header "Available Buildkits"
    packs = json_decode(server["/buildkits"].get)
    styled_array packs.map{|b| "#{b['org']}/#{b['name']}" }
  end
  alias_method :index, :list

  # buildkits:publish ORG/NAME
  #
  # publish a buildkits.
  #
  # -d, --buildpack-dir DIR # find buildpack in DIR instead of current directory
  #
  # If the organization doesn't yet exist, it will be created and you
  # will be added to it.
  #
  #Example:
  #
  # $ heroku buildkits:publish myorg/mypack
  # Publishing myorg/mypack buildkit... done, v4
  #
  def publish
    name = check_name(shift_argument)
    bp_dir = options[:buildpack_dir] || Dir.pwd

    if ! (File.executable?(File.join(bp_dir, "bin", "detect")) &&
          File.executable?(File.join(bp_dir, "bin", "compile")))
      abort "Buildpack #{bp_dir} missing bin/detect or bin/compile."
    end

    action "Publishing #{name} buildkit" do
      Dir.mktmpdir do |dir|
        %x{ cd #{bp_dir} && tar czf #{dir}/buildpack.tgz --exclude=.git . }

        begin
          buildpack = File.open("#{dir}/buildpack.tgz", "rb")
          response = server["/buildpacks/#{name}"].post(:buildpack => buildpack)
          revision = json_decode(response)["revision"]
          status "v#{revision}"
        rescue RestClient::Exception => e
          body = json_decode(e.http_body) || {"message" => "failed"}
          error body["message"]
        end
      end
    end
  end

  # buildkits:rollback ORG/NAME [REVISION]
  #
  # roll back a buildkit to an earlier revision
  #
  # If no revision is specified, use previous. Use
  # buildkits:revisions to see a full list.
  #
  #Example:
  #
  # $ heroku buildkits:rollback myorg/mypack v2
  # Rolling back myorg/mypack buildkit... done, Rolled back to v2 as v5
  #
  def rollback
    name = check_name(shift_argument)
    target = shift_argument || "previous"
    target = target.sub(/^v/, "")
    action "Rolling back #{name} buildkit" do
      begin
        response = server["/buildpacks/#{name}/revisions/#{target}"].post({})
        revision = json_decode(response)["revision"]
        target = target == "previous" ? target : "v#{target}"
        status "Rolled back to #{target} as v#{revision}"
      rescue RestClient::BadRequest => e
        error json_decode(e.http_body)["message"]
      rescue RestClient::Forbidden
        error "The '#{name}' buildkit is owned by someone else."
      rescue RestClient::ResourceNotFound
        error "The '#{name}' buildkit does not exist."
      end
    end
  end

  # buildkits:revisions ORG/NAME
  #
  # list buildkit revisions
  #
  #Example:
  #
  # $ h buildkits:revisions heroku/emacs
  # === Revisions
  # v4  2s ago   by me@myorg.org
  # v3  1m ago   by me@myorg.org
  # v2  2m ago   by me@myorg.org
  # v1  11m ago  by me@myorg.org
  #
  def revisions
    name = check_name(shift_argument)
    begin
      response = server["/buildpacks/#{name}/revisions"].get
      revisions = json_decode(response).reverse.map do |r|
        ["v#{r["id"]}", time_ago(r["created_at"]),
         "by #{r["published_by"]}"]
      end
      styled_header("Revisions")
      styled_array(revisions, :sort => false)
    rescue RestClient::BadRequest => e
      error json_decode(e.http_body)["message"]
    rescue RestClient::Forbidden
      error "The '#{name}' buildkit is owned by someone else."
    rescue RestClient::ResourceNotFound
      error "The '#{name}' buildkit does not exist."
    end
  end

  # buildkits:share ORG EMAIL
  #
  # Add user with EMAIL as a member of ORG
  #
  # Any member of an organization can publish to any buildkit owned
  # by that organization.
  #
  #Example:
  #
  # $ heroku buildkits:share myorg coworker@myorg.org
  # Adding coworker@myorg.org to myorg... done
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

  # buildkits:unshare ORG EMAIL
  #
  # Remove user with EMAIL from ORG
  #
  #Example:
  #
  # $ heroku buildkits:unshare myorg coworker@myorg.org
  # Removing coworker@myorg.org from myorg... done
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

  # buildkits:set BUILDKIT
  #
  # Use the specififed buildkit for the current app. You can pass in either
  # the organization/name or a URL to a tarball or git repo.
  #
  #Example:
  #
  # $ heroku buildkits:set kr/inline -a myapp
  # $ Using kr/inline for myapp... done
  #
  def set
    action "Modifying BUILDPACK_URL for #{app}" do
      buildpack_url = buildpack_url_for(shift_argument)
      api.put_config_vars(app, "BUILDPACK_URL" => buildpack_url)
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

  def buildpack_url_for(name)
    error("Must specify a buildkit") if name.nil?
    if name =~ /:\/\//
      name # is a URL
    else
      begin
        response = server["/buildpacks/#{name}"].get
        json_decode(response)["tar_link"]
      rescue RestClient::Exception => e
        body = json_decode(e.http_body) || {"message" => "failed"}
        error body["message"]
      end
    end
  end

  def check_name(name)
    if name.nil?
      error("Must specify a buildkit name")
    elsif not name =~ /\//
      error("Must include organization name, eg myorg/mypack")
    else
      name
    end
  end
end

