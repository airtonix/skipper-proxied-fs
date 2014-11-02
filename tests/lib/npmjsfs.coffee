Upstream = require 'skipper-proxied-fs/lib/filesystems/remote'
Proxied = require 'skipper-proxied-fs/lib/filesystems/local'

Error = require 'skipper-proxied-fs/errors'

###*
 * Upstream Filesystem Streaming Reciever/Sender
###


class NpmJSUpstream extends Upstream

	constructor: (@config) ->
		@user_agent = @config.user_agent
		@server_id = @config.server_id
		@ca = @config.ca
		@url = URL.parse config.url
		@logger = Logger.logger.child sub: 'out'

		@maxage = 300
		@failed_requests = 0
		@max_fails = @config.max_fails || 10
		@fail_timeout = @config.fail_timeout || 300

	get_package: (name, options, callback) ->

		headers = @_get_proxy_headers options.req
		if options.etag
			headers['If-None-Match'] = options.etag
			headers['Accept'] = 'application/octet-stream'

		request_config =
			uri: '/' + encode(name)
			json: true
			headers: headers

		@request request_config, (err, res, body) ->
			return callback(err) unless not err

			if  res.statusCode is 404
				return callback Error(404, "package doesn't exist on uplink")

			if not (res.statusCode >= 200 and res.statusCode < 300)
				error = Error "bad status code: #{res.statusCode}"
				error.remoteStatus = res.statusCode
				return callback error

			callback null, body, res.headers.etag

	get_url: (url) ->
		response_stream = new mystreams.ReadTarballStream()
		response_stream.abort = () ->
			#

		current_length = 0
		expected_length = undefined

		request_stream = @request
			uri_full: url
			encoding: null
			headers:
				Accept: 'application/octet-stream'

		request_stream.on 'response', (response) ->

			if (response.statusCode is 404)
				return response_stream.emit('error', Error(404, "file doesn't exist on uplink"))

			if not (response.statusCode >= 200 and response.statusCode < 300)
				return response_stream.emit('error', Error("bad uplink status code: #{response.statusCode}"))

			if _.has response.headers, 'content-length'
				expected_length = response.headers['content-length']
				response_stream.emit('content-length', response.headers['content-length'])

			request_stream.pipe response_stream

		request_stream.on 'error', (err) ->
			response_stream.emit 'error', err

		request_stream.on 'data', (d) ->
			current_length += d.length

		request_stream.on 'end', (d) ->
			if (d)
				current_length += d.length
			if (expected_length and current_length isnt expected_length)
				response_stream.emit 'error', Error('content length mismatch')

		return response_stream



class NpmJSFS extends ProxiedFS
	RemoteFS: NpmJSUpstream


module.exports = new NpmJSFS