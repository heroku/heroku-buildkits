require "heroku/command/base"

class Heroku::Command::Apps < Heroku::Command::Base

  alias_method :create_without_buildpack_shortcut, :create

  # apps:create [NAME]
  #
  # create a new app
  #
  #     --addons ADDONS        # a comma-delimited list of addons to install
  # -b, --buildpack BUILDPACK  # a buildpack url to use for this app
  # -n, --no-remote            # don't create a git remote
  # -r, --remote REMOTE        # the git remote to create, default "heroku"
  # -s, --stack STACK          # the stack on which to create the app
  #
  #Examples:
  #
  # $ heroku apps:create
  # Creating floating-dragon-42... done, stack is cedar
  # http://floating-dragon-42.heroku.com/ | git@heroku.com:floating-dragon-42.git
  #
  # $ heroku apps:create -s bamboo
  # Creating floating-dragon-42... done, stack is bamboo-mri-1.9.2
  # http://floating-dragon-42.herokuapp.com/ | git@heroku.com:floating-dragon-42.git
  #
  # # specify a name
  # $ heroku apps:create myapp
  # Creating myapp... done, stack is cedar
  # http://myapp.heroku.com/ | git@heroku.com:myapp.git
  #
  # # create a staging app
  # $ heroku apps:create myapp-staging --remote staging
  #
  def create
    if options[:buildpack] =~ %r{\A(\w+)/(\w+)\Z}
      options[:buildpack] = "http://codon-buildpacks.s3.amazonaws.com/buildpacks/#{$1}/#{$2}.tgz"
    end
    create_without_buildpack_shortcut
  end

end
