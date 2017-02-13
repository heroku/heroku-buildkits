'use strict'
/* globals describe it beforeEach afterEach */

const cli = require('heroku-cli-util')
const commands = require('../..').commands
const cmd = commands.find(c => c.topic === 'buildkits' && c.command === 'share')
const nock = require('nock')
const expect = require('unexpected')

describe('buildkits:share', () => {
  let api, heroku

  beforeEach(() => {
    cli.mockConsole()

    heroku = nock('https://api.heroku.com').get('/account').reply(200, {email: 'foo@foo.com'})
    api = nock('https://buildkits.heroku.com')
    api.post('/buildpacks/foo/share/foo@foo.com')
    .reply(201)
  })

  afterEach(() => {
    api.done()
    heroku.done()
    nock.cleanAll()
  })

  it('adds foo@foo.com to foo', () => {
    return cmd.run({auth: {password: 'foo'}, args: {org: 'foo', email: 'foo@foo.com'}})
    .then(() => {
      expect(cli.stderr, 'to equal', 'Adding foo@foo.com to foo... done\n')
      expect(cli.stdout, 'to be empty')
    })
  })
})
