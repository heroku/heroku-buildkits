'use strict'

exports.host = process.env.BUILDPACK_SERVER_URL || 'https://buildkits.heroku.com'

exports.auth = (context, heroku) => {
  return heroku.get('/account')
  .then(account => `${account.email}:${context.auth.password}`)
}
