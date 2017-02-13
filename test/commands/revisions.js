'use strict'
/* globals describe it beforeEach afterEach */

const cli = require('heroku-cli-util')
const commands = require('../..').commands
const cmd = commands.find(c => c.topic === 'buildkits' && c.command === 'revisions')
const nock = require('nock')
const expect = require('unexpected')

describe('buildkits', () => {
  let api

  beforeEach(() => {
    cli.mockConsole()
    api = nock('https://buildkits.heroku.com')
    api.get('/buildpacks/dickeyxxx/elixir/revisions')
    .reply(200, [
      {id: 1, created_at: new Date(), published_by: 'dickeyxxx'},
      {id: 2, created_at: new Date(), published_by: 'dickeyxxx'}
    ])
  })

  afterEach(() => {
    api.done()
    nock.cleanAll()
  })

  it('shows all the revision', () => {
    return cmd.run({args: {'org/name': 'dickeyxxx/elixir'}})
    .then(() => {
      expect(cli.stdout, 'to equal', `=== Revisions
v2  a few seconds ago  by dickeyxxx
v1  a few seconds ago  by dickeyxxx
`)
    })
  })
})
