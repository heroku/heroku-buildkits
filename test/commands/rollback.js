'use strict'
/* globals describe it beforeEach afterEach */

const cli = require('heroku-cli-util')
const commands = require('../..').commands
const cmd = commands.find(c => c.topic === 'buildkits' && c.command === 'rollback')
const nock = require('nock')
const expect = require('unexpected')

describe('buildkits:rollback', () => {
  let api, heroku

  beforeEach(() => {
    cli.mockConsole()

    heroku = nock('https://api.heroku.com').get('/account').reply(200, {email: 'foo@foo.com'})
    api = nock('https://buildkits.heroku.com')
    api.post('/buildpacks/dickeyxxx/elixir/revisions/2').reply(200)
  })

  afterEach(() => {
    api.done()
    heroku.done()
    nock.cleanAll()
  })

  it('adds foo@foo.com to foo', () => {
    return cmd.run({auth: {password: 'foo'}, args: {'org/name': 'dickeyxxx/elixir', revision: 'v2'}})
    .then(() => {
      expect(cli.stderr, 'to equal', 'Rolling back dickeyxxx/elixir to v2... done\n')
      expect(cli.stdout, 'to be empty')
    })
  })
})
