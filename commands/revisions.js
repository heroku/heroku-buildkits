'use strict'

const co = require('co')
const cli = require('heroku-cli-util')
const http = require('../lib/http')
const moment = require('moment')

function * run (context, heroku) {
  const name = context.args['org/name']

  cli.styledHeader('Revisions')
  let revisions = yield heroku.get(`/buildpacks/${name}/revisions`, {host: http.host})
  cli.table(revisions.reverse(), {
    printHeader: false,
    columns: [
      {key: 'id', format: i => `v${i}`},
      {key: 'created_at', format: d => moment(d).fromNow()},
      {key: 'published_by', format: u => `by ${u}`}
    ]
  })
}

module.exports = {
  topic: 'buildkits',
  command: 'revisions',
  args: [{name: 'org/name'}],
  run: cli.command(co.wrap(run))
}
