_ = require 'lodash'
Error = require '../errors'
FileSystemBase = require './base'

class RemoteFileSystem extends FileSystemBase

	read: (file_descripter, callback) ->
		# check if connections are possible
		if @_has_failed_too_much()
			#  if not, setup a fake response with an error
			return new Errors.StreamError "upstream #{@name} is offline"

		@current = @request()

	is_valid_url: (url) ->
		url = URL.parse(url)
		is_protocol = url.protocol is @url.protocol
		is_host = url.host is @url.host
		is_path = url.path.indexOf(@url.path) is 0
		return is_protocol and is_host and is_path

	get_failures_remaining: ->
		@max_fails - @failed_requests
	get_cooldown_remaining: ->
		@fail_timeout - Math.abs(Date.now() - @last_request_time)
	has_failed_too_much: ->
		@get_failures_remaining() is 0 and @get_cooldown_remaining() is 0

	get_default_headers: ->
		'Accept': 'application/json'
		'Accept-Encoding': 'gzip'
		'User-Agent': @user_agent

	get_proxy_headers: (request) ->
		headers = _.pluck request.headers, ['x-forwarded-for', 'via']

		if _.has headers, 'x-forwarded-for'
			headers['x-forwarded-for'] += request.connection.remoteAddress

		if _.has headers, 'via'
			headers['via'] += "1.1 #{@server_id} #{@user_agent}"

		return headers

	request: (options) ->

		request_config =
			url: options.uri_full || (@config.url + options.uri)
			headers: _.merge @_get_default_headers(), options.headers
			method: options.method || 'GET'
			json: if _.isObject options.json then JSON.stringify(options.json) else options.json
			ca: @ca
			proxy: @proxy
			encoding: null
			timeout: @timeout

		current_request = new request request_config, (err, response, body) ->

			response_length = if err then 0 else body.length

			gunzip_stream = (callback) ->
				return callback() unless not err or response.headers['content-encoding'] isnt 'gzip'
				zlib.gunzip body, (unzip_error, buffer) ->
					if unzip_error
						err = unzip_error
					body = buffer
					return callback()

		status_called = false


		current_request.on 'response', () =>
			if not status_called
				status_called = true
				if @_is_failure_limit_exceeded()
					console.log "host #{@config.url} is back online"
				@failed_requests = 0
				@last_request_time = Date.now()


		current_request.on 'error', () =>
			if not status_called
				status_called = true
				if @_is_failure_limit_exceeded()
					console.log "host #{@config.url} is now offline"
				@failed_requests++
				@last_request_time = Date.now()

		return current_request

module.exports = RemoteFileSystem
