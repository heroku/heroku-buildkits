require(File.expand_path(File.join(File.dirname(__FILE__), 'helper')))

class TestKits < Heroku::Test
  test_heroku("buildpacks:kit") do
    before { reset_db }
    stdout "=== Buildpacks in #{HEROKU_USER}'s kit\n\n"
  end

  test_heroku("buildpacks:add github/urweb") do
    before { heroku(publish("github", "urweb")) }
    stdout "Adding github/urweb to your kit... done\n"
  end

  test_heroku("buildpacks:add heroku/elixir") do
    before { heroku(publish("heroku", "elixir")) }
    stdout "Adding heroku/elixir to your kit... done\n"
  end

  test_heroku("buildpacks:add heroku/piet") do
    before { heroku(publish("heroku", "piet")) }
    stdout "Adding heroku/piet to your kit... done\n"
  end

  test_heroku("buildpacks:add heroku/opa") do
    status 1
    stdout "Adding heroku/opa to your kit... failed\n"
    stderr " !    No such buildpack: heroku/opa\n"
  end

  test_heroku("buildpacks:kit") do
    stdout "=== Buildpacks in phil.hagelberg+buildpack.test@heroku.com's kit
github/urweb
heroku/elixir
heroku/piet\n\n"
  end

  test_heroku("buildpacks:remove heroku/piet") do
    stdout "Removing heroku/piet from your kit... done\n"
  end

  test_heroku("buildpacks:remove heroku/piet") do
    stdout "Removing heroku/piet from your kit... failed\n"
    status 1
    stderr " !    The heroku/piet buildpack is not in your kit\n"
  end

  app = "buildpack-int-test-#{rand.to_s[2 .. 6]}"
  test_heroku("buildpacks:setup -a #{app}") do
    before { heroku "apps:create #{app}" }
    stdout "Modifying BUILDPACK_URL for #{app}... done\n"
  end

  test_heroku("build -r -a #{app}") do
    stdout(/Detecting buildpack... done, Buildkit/)
    after { heroku "apps:destroy #{app} --confirm #{app}" }
  end
end
