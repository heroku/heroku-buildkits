'use strict'
/* globals describe it beforeEach afterEach */

const cli = require('heroku-cli-util')
const nock = require('nock')
const expect = require('unexpected')
const proxyquire = require('proxyquire')
const exec = require('../mocks/exec')
const cmd = proxyquire('../../commands/set', {child_process: exec})

describe('buildkits:set', () => {
  let api

  beforeEach(() => {
    cli.mockConsole()

    api = nock('https://buildkits.heroku.com')
      .get('/buildpacks/dickeyxxx/elixir').reply(200, {tar_link: 'https://codon-buildpacks.s3.amazonaws.com/buildpacks/dickeyxxx/elixir.tgz'})
  })

  afterEach(() => {
    api.done()
    nock.cleanAll()
  })

  it('sets the buildpack to dickeyxxx/elixir', () => {
    return cmd.run({app: 'myapp', auth: {password: 'foo'}, args: {'org/name': 'dickeyxxx/elixir'}})
    .then(() => {
      expect(exec.cmd, 'to equal', 'heroku buildpacks:set https://codon-buildpacks.s3.amazonaws.com/buildpacks/dickeyxxx/elixir.tgz -a myapp')
    })
  })
})
