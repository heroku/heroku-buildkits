require(File.expand_path(File.join(File.dirname(__FILE__), 'helper')))

class TestRevisions < Heroku::Test
  test_heroku(publish("heroku", "piet")) do
    stdout "Publishing heroku/piet buildpack... done, v1\n"
  end

  test_heroku(publish("heroku", "piet", buildpack_dir("piet"))) do
    stdout "Publishing heroku/piet buildpack... done, v2\n"
  end

  test_heroku("buildpacks:revisions heroku/piet") do
    stdout(/=== Revisions\nv2 +\d+s ago\nv1 +\d+s ago/m)
  end
end
