'use strict'
/* globals describe it beforeEach afterEach */

const cli = require('heroku-cli-util')
const commands = require('../..').commands
const cmd = commands.find(c => c.topic === 'buildkits' && c.command === 'unshare')
const nock = require('nock')
const expect = require('unexpected')

describe('buildkits:unshare', () => {
  let api, heroku

  beforeEach(() => {
    cli.mockConsole()

    heroku = nock('https://api.heroku.com').get('/account').reply(200, {email: 'foo@foo.com'})
    api = nock('https://buildkits.heroku.com')
    api.delete('/buildpacks/foo/share/foo@foo.com').reply(200)
  })

  afterEach(() => {
    api.done()
    heroku.done()
    nock.cleanAll()
  })

  it('removes foo@foo.com from foo', () => {
    return cmd.run({auth: {password: 'foo'}, args: {org: 'foo', email: 'foo@foo.com'}})
    .then(() => {
      expect(cli.stderr, 'to equal', 'Removing foo@foo.com from foo... done\n')
      expect(cli.stdout, 'to be empty')
    })
  })
})
