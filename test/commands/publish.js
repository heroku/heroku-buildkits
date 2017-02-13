'use strict'
/* globals describe it beforeEach afterEach context */

const cli = require('heroku-cli-util')
const commands = require('../..').commands
const cmd = commands.find(c => c.topic === 'buildkits' && c.command === 'publish')
const nock = require('nock')
const expect = require('unexpected')

describe('buildkits:share', () => {
  context('with valid args', () => {
    let api, heroku

    beforeEach(() => {
      cli.mockConsole()

      heroku = nock('https://api.heroku.com').get('/account').reply(200, {email: 'foo@foo.com'})
      api = nock('https://buildkits.heroku.com')
      api.post('/buildpacks/dickeyxxx/elixir').reply(200, {revision: '8'})
    })

    afterEach(() => {
      api.done()
      heroku.done()
      nock.cleanAll()
    })

    it('publishes the elixer buildpack', () => {
      return cmd.run({auth: {password: 'foo'}, args: {'org/name': 'dickeyxxx/elixir'}, flags: {'buildpack-dir': 'test_buildpacks/elixir'}})
      .then(() => {
        expect(cli.stderr, 'to equal', 'Publishing dickeyxxx/elixir buildkit... v8\n')
        expect(cli.stdout, 'to be empty')
      })
    })
  })

  it('errors with invalid directory', () => {
    return expect(cmd.run({auth: {password: 'foo'}, args: {'org/name': 'dickeyxxx/elixir'}, flags: {'buildpack-dir': '.'}})
                  , 'to be rejected with', 'Buildpack . missing bin/detect or bin/compile')
  })
})
