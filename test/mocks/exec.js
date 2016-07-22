'use strict'

exports.cmd = []

exports.execSync = function (cmd) {
  exports.cmd.push(cmd)
}
