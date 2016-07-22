'use strict'

exports.topic = {
  name: 'buildkits',
  description: 'manage buildpacks'
}

exports.commands = [
  require('./commands'),
  require('./commands/publish'),
  require('./commands/share'),
  require('./commands/unshare')
]
