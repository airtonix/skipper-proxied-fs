_ = require 'lodash'
path = require 'path'

ProxiedFS = require './filesystems/proxied'

###*
 * skipper-npmjs
 * 
###

module.exports = (global_options) ->

	return new ProxiedFS()