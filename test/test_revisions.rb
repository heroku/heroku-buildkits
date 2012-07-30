require(File.expand_path(File.join(File.dirname(__FILE__), 'helper')))

class TestRevisions < Heroku::Test
  test_heroku(publish("heroku", "piet")) do
    stdout "Publishing heroku/piet buildpack... done, v1\n"
  end

  test_heroku(publish("heroku", "piet", buildpack_dir("elixir"))) do
    stdout "Publishing heroku/piet buildpack... done, v2\n"
  end

  test_heroku("build -b #{buildpack_url('piet')}") do
    stdout(/Detecting buildpack... done, Elixir.*Success, slug is/m)
  end

  test_heroku("buildpacks:revisions heroku/piet") do
    stdout(/=== Revisions\nv2 +\d+s ago\nv1 +\d+s ago/m)
  end

  test_heroku("buildpacks:rollback heroku/piet") do
    stdout "Rolling back heroku/piet buildpack... done, Rolled back to previous as v3\n"
  end

  test_heroku("buildpacks:revisions heroku/piet") do
    stdout(/=== Revisions\nv3 +\d+s ago\nv2 +\d+s ago\nv1 +\d+s ago/m)
  end

  test_heroku("build -b #{buildpack_url('piet')}") do
    stdout(/Detecting buildpack... done, Piet.*Success, slug is/m)
  end
end
