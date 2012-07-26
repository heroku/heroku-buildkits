require(File.expand_path(File.join(File.dirname(__FILE__), 'helper')))

class TestPublish < Heroku::Test
  def self.publish(org, name)
    "buildpacks:publish #{org}/#{name} -d #{buildpack_dir(name)}"
  end

  test_heroku(publish("jimmy", "elixir")) do
    status(0)
    stderr("")
    stdout("")
  end
end
