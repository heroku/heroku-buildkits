'use strict'
/* globals describe it beforeEach afterEach */

const cli = require('heroku-cli-util')
const commands = require('../..').commands
const cmd = commands.find(c => c.topic === 'buildkits' && !c.command)
const nock = require('nock')
const expect = require('unexpected')

describe('buildkits', () => {
  let api

  beforeEach(() => {
    cli.mockConsole()
    api = nock('https://buildkits.heroku.com')
    api.get('/buildpacks')
    .reply(200, [
      {org: 'b', name: 'a'},
      {org: 'a', name: 'b'},
      {org: 'b', name: 'b'},
      {org: 'a', name: 'a'}
    ])
  })

  afterEach(() => {
    api.done()
    nock.cleanAll()
  })

  it('shows all the buildkits', () => {
    return cmd.run({})
    .then(() => {
      expect(cli.stdout, 'to equal', `=== Available Buildkits
a/a
a/b
b/a
b/b
`)
    })
  })
})
