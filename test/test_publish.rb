require(File.expand_path(File.join(File.dirname(__FILE__), 'helper')))

class TestPublish < Heroku::Test
  def self.publish(org, name)
    "buildpacks:publish #{org}/#{name} -d #{buildpack_dir(name)}"
  end

  reset_db

  test_heroku(publish("github", "elixir")) do
    status(0)
    stderr("")
    stdout("Publishing github/elixir buildpack... done, v1\n")
  end

  test_heroku(publish("github", "elixir")) do
    status(0)
    stderr("")
    stdout("Publishing github/elixir buildpack... done, v2\n")
  end

  # publish to other org, unauthorized
  # share as other user
  # publish to other org, authorized
  # unshare as uthor user
  # publish to other org, unauthorized
end
