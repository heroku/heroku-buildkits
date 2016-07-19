'use strict'

const co = require('co')
const cli = require('heroku-cli-util')
const fs = require('mz/fs')
const path = require('path')
const tmp = require('tmp')
const execa = require('execa')
const http = require('../lib/http')

function checkname (name) {
  if (name.indexOf('/') === -1) throw new Error('Must include organization name, eg: myorg/mypack')
}

function validateBuildpack (d) {
  if (!fs.exists(path.join(d, 'bin', 'detect')) ||
      !fs.exists(path.join(d, 'bin', 'compile'))) {
    throw new Error(`Buildpack ${d} missing bin/detect or bin/compile`)
  }
}

function * run (context, heroku) {
  const name = context.args['org/name']
  checkname(name)

  const d = context.flags['buildpack-dir'] || process.cwd()
  validateBuildpack(d)

  yield cli.action(`Publishing ${name} buildkit`, {success: false}, co(function * () {
    const tmpdir = tmp.dirSync().name
    const tgz = path.join(tmpdir, 'buildpack.tgz')
    yield execa.shell(`cd ${d} && tar czf ${tgz} --exclude=.git .`)
    const buildpack = yield fs.readFile(tgz)
    const response = yield heroku.post(`/buildpacks/${name}`, {
      host: http.host,
      body: {buildpack}
    })
    cli.action.done(response.revision)
  }))
}

module.exports = {
  topic: 'buildkits',
  command: '_publish',
  description: 'publish a buildkit',
  help: "If the organization doesn't exist, it will be created and you will be added to it.",
  args: [
    {name: 'org/name'}
  ],
  flags: [
    {name: 'buildpack-dir', char: 'd', description: 'find buildpack in DIR instead of current dir', hasValue: true}
  ],
  run: cli.command(co.wrap(run))
}
