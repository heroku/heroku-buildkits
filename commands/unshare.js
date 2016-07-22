'use strict'

const co = require('co')
const cli = require('heroku-cli-util')
const http = require('../lib/http')

function * run (context, heroku) {
  const {org, email} = context.args

  yield cli.action(`Removing ${email} from ${org}`, co(function * () {
    yield heroku.delete(`/buildpacks/${org}/share/${email}`, {
      auth: yield http.auth(context, heroku),
      host: http.host
    })
  }))
}

module.exports = {
  topic: 'buildkits',
  command: 'unshare',
  description: 'remove EMAIL from buildkit ORG',
  needsAuth: true,
  args: [
    {name: 'org'},
    {name: 'email'}
  ],
  run: cli.command(co.wrap(run))
}
