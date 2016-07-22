'use strict'

const co = require('co')
const cli = require('heroku-cli-util')
const http = require('../lib/http')

function * run (context, heroku) {
  const sortBy = require('lodash.sortby')

  cli.styledHeader('Available Buildkits')
  let buildpacks = yield heroku.get('/buildpacks', {host: http.host})
  buildpacks = sortBy(buildpacks, 'org', 'name')
  for (let buildpack of buildpacks) {
    cli.log(`${buildpack.org}/${buildpack.name}`)
  }
}

module.exports = {
  topic: 'buildkits',
  run: cli.command(co.wrap(run))
}
