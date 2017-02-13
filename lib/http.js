'use strict'

let herokuHost = process.env.HEROKU_HOST || 'heroku.com'

exports.host = process.env.BUILDPACK_SERVER_URL || `https://buildkits.${herokuHost}`

exports.auth = (context, heroku) => {
  return heroku.get('/account')
  .then(account => `${account.email}:${context.auth.password}`)
}
