_ = require 'lodash'
fs = require 'fs-extra'
path = require 'path'

FileSystemBase = require './base'


class LocalFileSystem extends FileSystemBase

	constructor: (@options) ->
		@name = @options.name
		@description = @options.description
		@root = @options.root

	exists: (target) ->
		fs.existsSync target


	read: (file_descripter, callback) ->
		filepath = path.join(@root, file_descripter)
		return callback() unless @exists filepath
		fs.readFile filepath, callback

	readSync: (file_descripter) ->
		filepath = path.join(@root, file_descripter)
		fs.readFileSync filepath

	ls: (directory, callback) ->
		return callback() unless @exists directory
		fs.readdir directory, callback


	rm: (file_descripter, callback) ->
		return callback() unless @exists file_descripter

		fsx.unlink file_descripter, (err)->
			# Ignore "doesn't exist" errors
			if err and not _.isObject(err) or err.code isnt 'ENOENT'
				return cb(err);
			else
				return cb();

	recieve: (options) ->

		# receiver = Writable
		# 	objectMode: true

		# receiver.once 'error', (err) ->
		# 	console.log 'ERROR ON RECEIVER__ ::', err

		# receiver._write = onFile (newFile, encoding, next) ->
		# 	startedAt = new Date()
		# 	newFile.once 'error', (err) ->


		# 	if _.isUndefined headers['content-type']
		# 		headers['content-type'] = mime.lookup __newFile.fd

module.exports = LocalFileSystem
