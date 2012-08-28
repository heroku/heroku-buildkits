require(File.expand_path(File.join(File.dirname(__FILE__), 'helper')))

class TestRevisions < Heroku::Test
  test_heroku(publish("heroku", "piet")) do
    before { reset_db }
    stdout "Publishing heroku/piet buildpack... done, v1\n"
  end

  test_heroku(publish("heroku", "piet", buildpack_dir("elixir"))) do
    stdout "Publishing heroku/piet buildpack... done, v2\n"
  end

  test_heroku("build -b #{buildpack_url('piet')}") do
    stdout(/Detecting buildpack... done, Elixir.*Success, slug is/m)
  end

  test_heroku("buildpacks:revisions heroku/piet") do
    stdout(/=== Revisions\nv2 +\d+[sm] ago +by #{Regexp.escape(HEROKU_USER)}\nv1 +\d+[sm] ago +by /m)
  end

  test_heroku("buildpacks:rollback heroku/piet") do
    stdout "Rolling back heroku/piet buildpack... done, Rolled back to previous as v3\n"
  end

  test_heroku("buildpacks:revisions heroku/piet") do
    stdout(/=== Revisions\nv3 +\d+[sm] ago +by #{Regexp.escape(HEROKU_USER)}\nv2 +\d+[sm] ago +by /m)
  end

  # push a build all the way out via anvil
  app = "buildpack-int-test-#{rand.to_s[2 .. 6]}"

  test_heroku("build -b #{buildpack_url('piet')} -r -a #{app}") do
    before { heroku "apps:create #{app}" }
    stdout(/Detecting buildpack... done, Piet.*Success, slug is/m)
    after do
      proc = open("http://#{app}.herokuapp.com/Procfile").read
      # for some reason assert_match isn't available here
      raise MiniTest::Assertion, "build failed" unless proc =~ /SimpleHTTPServer/
      heroku "apps:destroy #{app} --confirm #{app}"
    end
  end
end
