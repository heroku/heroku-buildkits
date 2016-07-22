# heroku-buildkits [![CircleCI](https://circleci.com/gh/heroku/heroku-buildkits.svg?style=svg)](https://circleci.com/gh/heroku/heroku-buildkits)

[![codecov](https://codecov.io/gh/heroku/heroku-buildkits/branch/master/graph/badge.svg)](https://codecov.io/gh/heroku/heroku-buildkits)

Publish and consume buildkits on Heroku.

## Installation

    $ heroku plugins:install heroku-buildkits

## Buildkit Maintainers

### Publish a buildkit

	$ cd ~/awesomepack
	$ heroku buildkits:publish mycorp/awesomepack

### Revisions

    $ heroku buildkits:revisions mycorp/awesomepack
    === Revisions
    3   2012/06/29 13:45:33
    2   2012/06/29 13:44:16
    1   2012/06/28 17:23:06

    $ heroku buildkits:rollback mycorp/awesomepack 2
    Rolling back mycorp/awesomepack buildkit... Rolled back to 2 as revision 4
    done

## Buildkit Users

The `buildkits:set` command will configure an app to use a given
buildkit.

	$ heroku buildkits:set kr/inline -a myapp
