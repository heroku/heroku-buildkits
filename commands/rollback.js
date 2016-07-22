'use strict'

const co = require('co')
const cli = require('heroku-cli-util')
const http = require('../lib/http')

function * run (context, heroku) {
  const name = context.args['org/name']
  const revision = context.args.revision || 'previous'

  yield cli.action(`Rolling back ${name} to ${revision}`, co(function * () {
    yield heroku.post(`/buildpacks/${name}/revisions/${revision.replace(/^v/, '')}`, {
      auth: yield http.auth(context, heroku),
      host: http.host
    })
  }))
}

module.exports = {
  topic: 'buildkits',
  command: 'rollback',
  description: 'rollback a buildkit to an earlier revision',
  help: 'If no revision is specified, use previous.',
  needsAuth: true,
  args: [
    {name: 'org/name'},
    {name: 'revision', optional: true}
  ],
  run: cli.command(co.wrap(run))
}
