_ = require 'lodash'
request = require 'request'
stream = require 'stream'
URL = require 'url'

Errors = require '../errors'
FileSystemBase = require './base'


class ProxiedFS extends FileSystemBase

	constructor: (@options)->
		if _.has @options, 'upstream'
			@UpstreamFsClass = @options.upstreamfs_class
		else
			@UpstreamFsClass = require './remote'

		if _.has @options, 'localfs_class'
			@LocalFileSystem = @options.localfs_class
		else
			@UpstreamFsClass = require './local'

		for name, silo_options in @options.silos.upstream
			@upstreams[name] = new @RemoteFS silo_options

		for name, silo_options in @options.silos.local
			@locals[name] = new @LocalFS silo_options

	# rm: (file, callback) ->
	# ls: (file, callback) ->
	# read: (file, callback) ->
	# recieve: (file, callback) ->

module.exports = ProxiedFS