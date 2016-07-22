'use strict'

const co = require('co')
const cli = require('heroku-cli-util')
const http = require('../lib/http')
const {execSync} = require('child_process')

function * run (context, heroku) {
  const app = context.app
  const name = context.args['org/name']

  const buildkit = yield heroku.get(`/buildpacks/${name}`, {host: http.host})

  execSync(`heroku buildpacks:set ${buildkit.tar_link} -a ${app}`, {stdio: 'inherit'})
}

module.exports = {
  topic: 'buildkits',
  command: 'set',
  description: 'Add the specififed buildkit to the current app. You can pass in either the organization/name or a URL to a tarball or git repo.',
  needsAuth: true,
  needsApp: true,
  args: [{name: 'org/name'}],
  run: cli.command(co.wrap(run))
}
