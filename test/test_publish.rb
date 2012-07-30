require(File.expand_path(File.join(File.dirname(__FILE__), 'helper')))

class TestPublish < Heroku::Test
  def self.publish(org, name)
    "buildpacks:publish #{org}/#{name} -d #{buildpack_dir(name)}"
  end

  reset_db

  test_heroku(publish("heroku", "elixir")) do
    stdout "Publishing heroku/elixir buildpack... done, v1\n"
  end

  test_heroku(publish("heroku", "elixir")) do
    stdout "Publishing heroku/elixir buildpack... done, v2\n"
  end

  test_heroku(publish("heroku", "elixir"), :user => :other) do
    stdout "Publishing heroku/elixir buildpack... failed\n"
    stderr " !    Not a member of that organization.\n"
    status 1
  end

  test_heroku(publish("github", "urweb"), :user => :other) do
    stdout "Publishing github/urweb buildpack... done, v1\n"
  end

  test_heroku(publish("github", "urweb")) do
    stdout "Publishing github/urweb buildpack... failed\n"
    stderr " !    Not a member of that organization.\n"
    status 1
  end

  test_heroku("buildpacks:share github #{HEROKU_USER}", :user => :other) do
    stdout "Adding wesley+fisticuffs@heroku.com to github... done\n"
  end

  test_heroku(publish("github", "urweb")) do
    stdout "Publishing github/urweb buildpack... done, v2\n"
  end

  test_heroku("buildpacks:unshare github #{HEROKU_USER}", :user => :other) do
    stdout "Removing wesley+fisticuffs@heroku.com from github... done\n"
  end

  test_heroku(publish("github", "urweb")) do
    stdout "Publishing github/urweb buildpack... failed\n"
    stderr " !    Not a member of that organization.\n"
    status 1
  end
end
