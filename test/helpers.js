'use strict'

const cli = require('heroku-cli-util')
cli.raiseErrors = true                         // Fully raise exceptions
process.env.TZ = 'UTC'                         // Use UTC time always
process.stdout.columns = 80                    // Set screen width for consistent wrapping
process.stderr.columns = 80                    // Set screen width for consistent wrapping

const nock = require('nock')
nock.disableNetConnect()
