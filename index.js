'use strict'

exports.topic = {
  name: 'buildkits',
  description: 'manage buildpacks'
}

exports.commands = [
  require('./commands'),
  require('./commands/add'),
  require('./commands/publish'),
  require('./commands/revisions'),
  require('./commands/rollback'),
  require('./commands/set'),
  require('./commands/share'),
  require('./commands/unshare')
]
