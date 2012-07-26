require(File.expand_path(File.join(File.dirname(__FILE__), 'helper')))

class TestPublish < Heroku::Test
  test_heroku(publish("heroku", "elixir")) do
    stdout "Publishing heroku/elixir buildpack... done, v1\n"
  end

  test_heroku(publish("heroku", "elixir")) do
    stdout "Publishing heroku/elixir buildpack... done, v2\n"
  end

  test_heroku("build -b #{buildpack_url('elixir')}") do
    stdout(/Detecting buildpack... done, Elixir.*Success, slug is/m)
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
    stdout "Adding #{HEROKU_USER} to github... done\n"
  end

  test_heroku(publish("github", "urweb")) do
    stdout "Publishing github/urweb buildpack... done, v2\n"
  end

  test_heroku("build -b #{buildpack_url('urweb', 'github')}") do
    stdout(/Detecting buildpack... done, Ur\/Web.*Success, slug is/m)
  end

  test_heroku("buildpacks:unshare github #{HEROKU_USER}", :user => :other) do
    stdout "Removing #{HEROKU_USER} from github... done\n"
  end

  test_heroku(publish("github", "urweb")) do
    stdout "Publishing github/urweb buildpack... failed\n"
    stderr " !    Not a member of that organization.\n"
    status 1
  end
end
