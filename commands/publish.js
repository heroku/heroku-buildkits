'use strict'

const co = require('co')
const cli = require('heroku-cli-util')
const fs = require('mz/fs')
const path = require('path')
const tmp = require('tmp')
const execa = require('execa')
const http = require('../lib/http')
const FormData = require('form-data')
const url = require('url')

function checkname (name) {
  if (name.indexOf('/') === -1) throw new Error('Must include organization name, eg: myorg/mypack')
}

function validateBuildpack (d) {
  if (!fs.existsSync(path.join(d, 'bin', 'detect')) ||
      !fs.existsSync(path.join(d, 'bin', 'compile'))) {
    throw new Error(`Buildpack ${d} missing bin/detect or bin/compile`)
  }
}

function submitForm (form, params) {
  let host = url.parse(params.host)
  let http = require(host.protocol === 'https:' ? 'https' : 'http')
  let data = ''
  return new Promise((resolve, reject) => {
    const headers = form.getHeaders()
    let req = http.request(Object.assign(host, {headers}, params), res => {
      res.setEncoding('utf8')
      if (res.statusCode > 299) reject(new Error(res.statusCode))
      res.on('data', d => { data += d })
      res.on('end', () => resolve(JSON.parse(data)))
    })
    form.pipe(req)
  })
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
    let form = new FormData()
    form.append('buildpack', fs.createReadStream(tgz))
    const response = yield submitForm(form, {
      path: `/buildpacks/${name}`,
      method: 'POST',
      auth: yield http.auth(context, heroku),
      host: http.host
    })
    cli.action.done(`v${response.revision}`)
  }))
}

module.exports = {
  topic: 'buildkits',
  command: 'publish',
  description: 'publish a buildkit',
  help: "If the organization doesn't exist, it will be created and you will be added to it.",
  needsAuth: true,
  args: [
    {name: 'org/name'}
  ],
  flags: [
    {name: 'buildpack-dir', char: 'd', description: 'find buildpack in DIR instead of current dir', hasValue: true}
  ],
  run: cli.command(co.wrap(run))
}
