'use strict'

const co = require('co')
const cli = require('heroku-cli-util')
const http = require('../lib/http')

function * run (context, heroku) {
  const {org, email} = context.args

  yield cli.action(`Adding ${email} to ${org}`, co(function * () {
    yield heroku.post(`/buildpacks/${org}/share/${email}`, {
      auth: yield http.auth(context, heroku),
      host: http.host
    })
  }))
}

module.exports = {
  topic: 'buildkits',
  command: 'share',
  description: 'add EMAIL to buildkit ORG',
  help: 'Any member of an organization can publish to any buildkit owned by that organization.',
  needsAuth: true,
  args: [
    {name: 'org'},
    {name: 'email'}
  ],
  run: cli.command(co.wrap(run))
}
