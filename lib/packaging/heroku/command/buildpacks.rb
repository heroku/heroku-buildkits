require "heroku/command"
require "tmpdir"
require "rest_client"

# manage buildpacks
#
class Heroku::Command::Buildpacks < Heroku::Command::Base

  # buildpacks:list
  #
  # list all available buildpacks
  #
  #Example:
  #
  # $ heroku buildpacks:list
  #
  # === Available Buildpacks
  # heroku/clojure
  # heroku/emacs
  # heroku/erlang
  # myorg/mypack
  # [...]
  #
  def list
    styled_header "Available Buildpacks"
    packs = json_decode(server["/buildpacks"].get)
    styled_array packs.map{|b| "#{b['org']}/#{b['name']}" }
  end
  alias_method :index, :list

  # buildpacks:publish ORG/NAME
  #
  # publish a buildpack.
  #
  # -d, --buildpack-dir DIR # find buildpack in DIR instead of current directory
  #
  # If the organization doesn't yet exist, it will be created and you
  # will be added to it.
  #
  #Example:
  #
  # $ heroku buildpacks:publish myorg/mypack
  # Publishing myorg/mypack buildpack... done, v4
  #
  def publish
    name = check_name(shift_argument)
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
          body = json_decode(e.http_body) || {"message" => "failed"}
          error body["message"]
        end
      end
    end
  end

  # buildpacks:rollback ORG/NAME [REVISION]
  #
  # roll back a buildpack to an earlier revision
  #
  # If no revision is specified, use previous. Use
  # buildpacks:revisions to see a full list.
  #
  #Example:
  #
  # $ heroku buildpacks:rollback myorg/mypack v2
  # Rolling back myorg/mypack buildpack... done, Rolled back to v2 as v5
  #
  def rollback
    name = check_name(shift_argument)
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
  #Example:
  #
  # $ h buildpacks:revisions heroku/emacs
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
        ["v#{r["id"]}", time_ago((Time.now - Time.parse(r["created_at"])).to_i),
         "by #{r["published_by"]}"]
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
  # Any member of an organization can publish to any buildpack owned
  # by that organization.
  #
  #Example:
  #
  # $ heroku buildpacks:share myorg coworker@myorg.org
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

  # buildpacks:unshare ORG EMAIL
  #
  # Remove user with EMAIL from ORG
  #
  #Example:
  # $ heroku buildpacks:unshare myorg coworker@myorg.org
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

  def check_name(name)
    if name.nil?
      error("Must specify a buildpack name")
    elsif not name =~ /\//
      error("Must include organization name, eg myorg/mypack")
    else
      name
    end
  end
end

