fsx = require("fs-extra")
assert = require("assert")
_ = require("lodash")
skipper = require("skipper")
connect = require("connect")
routify = require("routification")
Temporary = require("temporary")
crypto = require("crypto")
request = require("request")



###*
Module dependencies
###
class Helpers

	fileFixtures = undefined
	outputDir = undefined
	server = undefined
	app = undefined
	PORT = 1337

	###*
	 * [create_file description]
	 * @param  {[type]} numBytes
	 * @return {[type]}
	###
	create_file: (numBytes) ->
		EOF = "\u0004"
		file = new Temporary.File()
		file.writeFileSync crypto.pseudoRandomBytes(numBytes) + EOF
		file.size = numBytes
		file


	###*
	[setup description]
	@return {[type]} [description]
	###
	setup: (options, done) ->

		# Build HTTP server and listen on a port.
		app = connect()
		app.set "baseurl", "http://localhost:#{PORT}"

		# Create an array of file fixtures.
		fileFixtures = []

		# Write nonsense bytes to our file fixtures.
		bytes = 10

		while bytes < 100000
			fileFixtures.push @create_file bytes
			bytes *= 10

		app.fixtures =
			files: fileFixtures
			# Create a tmp directory for our uploads to live in.
			dir: new Temporary.Dir()


		app = routify(app)
		app.use skipper()
		# Give ourselves a dumbed-down impl. of res.json()
		# and res.send() to make things easier in the tests
		# (these will not work all the time)
		app.use (req, res, next) ->
			res.send = (body) ->
				res.write body
				res.end()

			res.json = (body) ->
				body = JSON.stringify(body)
				res.send body

			next()

		server = app.listen(PORT, done)

		return server

	###*
	[teardown description]
	@return {[type]} [description]
	###
	teardown: (app, done) ->

		# Clean up fixtures.
		_.each app.fixtures.files, (f) ->
			f.unlinkSync()

		# Clean up directory w/ test output.
		fsx.removeSync outputDir.path

		# Teardown the HTTP server.
		server.close done


module.exports = new Helpers()
