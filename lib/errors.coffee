Stream = require 'stream'
Error = require 'http-errors'


Error.StreamError = class StreamError extends Stream.Readable

	constructor: (message) ->
		process.nextTick () ->
			if _.isFunction callback
				callback Error message
			@emit 'error', Error 'uplink is offline'

		@on 'error', () ->

module.export = Error
