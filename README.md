# heroku-buildpacks

Use buildpack kits on Heroku

## Installation

    $ heroku plugins:install https://github.com/heroku/heroku-buildpacks

## Usage

### Publish a buildpack

	$ cd ~/awesomepack
	$ heroku buildpacks:publish awesomepack

### Roll back

    $ heroku buildpacks:revisions awesomepack
    === Revisions
    3   2012/06/29 13:45:33
    2   2012/06/29 13:44:16
    1   2012/06/28 17:23:06

    $ heroku buildpacks:rollback awesomepack 2
    Rolling back clojure buildpack... Rolled back to 2 as revision 4
    done

### Set up your Heroku app to use buildpack kits

	$ heroku buildpacks:setup -a myapp

### Push your app

When you push, every buildpack in your kit will be evaluated for a match. All buildpacks that match (using `bin/detect`) will be used in sequence to compile your application.

	$ git push heroku master
	Counting objects: 5, done.
	Delta compression using up to 4 threads.
	Compressing objects: 100% (2/2), done.
	Writing objects: 100% (3/3), 252 bytes, done.
	Total 3 (delta 1), reused 0 (delta 0)

	-----> Heroku receiving push
	-----> Fetching custom buildpack... done
	-----> Buildkit+AwesomePack+OtherPack app detected
	-----> Compiling for AwesomePack
	       ...
	-----> Compiling for OtherPack
	       ...

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
