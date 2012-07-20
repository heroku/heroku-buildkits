require "heroku/command"
require "tmpdir"
require "rest_client"

# manage buildpacks
#
class Heroku::Command::Buildpacks < Heroku::Command::Base

  # # buildpacks
  # #
  # # list the buildpacks in your kit
  # #
  # def index
  #   styled_header "Buildpacks in #{auth.user}'s kit"
  #   styled_array json_decode(server["/user/buildpacks"].get)
  # end

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
    styled_array json_decode(server["/buildpacks"].get).map{|b| b["name"]}
  end

  # # buildpacks:add NAME
  # #
  # # add a buildpack to your kit
  # #
  # def add
  #   name = shift_argument || error("Must specify a buildpack name")
  #   action("Adding #{name} to your kit") do
  #     begin
  #       server["/user/buildpacks"].post(:name => name)
  #     rescue RestClient::ResourceNotFound
  #       error "No such buildpack: #{name}"
  #     rescue RestClient::Forbidden
  #       error "The #{name} buildpack is already in your kit"
  #     end
  #   end
  # end

  # # buildpacks:remove NAME
  # #
  # # remove a buildpack from your kit
  # #
  # def remove
  #   name = shift_argument || error("Must specify a buildpack name")
  #   action("Removing #{name} from your kit") do
  #     begin
  #       server["/user/buildpacks/#{name}"].delete
  #     rescue RestClient::ResourceNotFound
  #       error "The #{name} buildpack is not in your kit"
  #     end
  #   end
  # end

  # buildpacks:publish NAME
  #
  # publish a buildpack
  #
  def publish
    name = shift_argument || error("Must specify a buildpack name")

    action "Publishing #{name} buildpack" do
      Dir.mktmpdir do |dir|
        %x{ tar czf #{dir}/buildpack.tgz * }

        begin
          buildpack = File.open("#{dir}/buildpack.tgz", "rb")
          response = server["/buildpacks/#{name}"].post(:buildpack => buildpack)
          revision = json_decode(response)["revision"]
          status "v#{revision}"
        rescue RestClient::Forbidden
          error "The name '#{name}' is already taken."
        end
      end
    end
  end

  # buildpacks:rollback NAME [REVISION]
  #
  # roll back a buildpack to specified revision or previous
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
      rescue RestClient::Forbidden
        error "The '#{name}' buildpack is owned by someone else."
      rescue RestClient::ResourceNotFound
        error "The '#{name}' buildpack does not exist."
      end
    end
  end

  # buildpacks:revisions NAME
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
    rescue RestClient::Forbidden
      error "The '#{name}' buildpack is owned by someone else."
    rescue RestClient::ResourceNotFound
      error "The '#{name}' buildpack does not exist."
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
    RestClient::Resource.new buildkit_host, :user => auth.user, :password => auth.password
  end

end

