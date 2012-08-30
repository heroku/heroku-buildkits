# heroku-buildpacks

Publish and consume buildpacks on Heroku.

## Installation

    $ heroku plugins:install https://github.com/heroku/heroku-buildpacks

## Buildpack Maintainers

### Publish a buildpack

	$ cd ~/awesomepack
	$ heroku buildpacks:publish mycorp/awesomepack

### Revisions

    $ heroku buildpacks:revisions mycorp/awesomepack
    === Revisions
    3   2012/06/29 13:45:33
    2   2012/06/29 13:44:16
    1   2012/06/28 17:23:06

    $ heroku buildpacks:rollback mycorp/awesomepack 2
    Rolling back mycorp/awesomepack buildpack... Rolled back to 2 as revision 4
    done

## Buildpack Users

The `buildpacks:set` command will configure an app to use a given buildpack.

	$ heroku buildpacks:set kr/inline -a myapp

## Developing

To run the tests, you'll need
[buildkits](https://github.com/heroku/buildkits) running locally.
Currently you'll need to launch the server by hand. First some setup:

    $ createdb buildkits-test
    $ DATABASE_URL=postgres://localhost:5432/buildkits-test lein run -m buildkits.db.migrate

Then to run:

    $ DATABASE_URL=postgres://localhost:5432/buildkits-test lein run -m buildkits.web &
    $ export HEROKU_USER=[...] HEROKU_API_KEY=[...] HEROKU_OTHER_USER=[...] HEROKU_OTHER_API_KEY=[...]
    $ bundle exec rake
