fs = require("fs")
Path = require("path")
mkdirp = require("mkdirp")
mystreams = require("./streams")
Error = require("http-errors")


try
	fsExt = require("fs-ext")
catch e
	fsExt = flock: ->
		arguments[arguments.length - 1]()
		return


FSError = (code) ->
	err = Error(code)
	err.code = code
	err


class LocalStorage

	###*
	 * [unlink description]
	 * @type {[type]}
	###
	unlink: fs.unlink

	###*
	 * [rmdir description]
	 * @type {[type]}
	###
	rmdir: fs.rmdir

	###*
	 * [write description]
	 * @param  {[type]}   dest
	 * @param  {[type]}   data
	 * @param  {Function} cb
	 * @return {[type]}
	###
	write: (dest, data, cb) ->

		safe_write = (cb) ->
			tmpname = dest + ".tmp" + String(Math.random()).substr(2)
			fs.writeFile tmpname, data, (err) ->
				return cb(err)  if err
				fs.rename tmpname, dest, cb

		safe_write (err) ->
			if err and err.code is "ENOENT"
				mkdirp Path.dirname(dest), (err) ->
					return cb(err)  if err
					safe_write cb

			else
				cb err

	###*
	 * [write_stream description]
	 * @param  {[type]} name
	 * @return {[type]}
	###
	write_stream: (name) ->
		stream = new mystreams.UploadTarballStream()
		_ended = false
		stream.on "end", ->
			_ended = true

		fs.exists name, (exists) ->
			return stream.emit("error", FSError("EEXISTS"))  if exists
			tmpname = name + ".tmp-" + String(Math.random()).replace(/^0\./, "")
			file = fs.createWriteStream(tmpname)
			opened = false
			stream.pipe file
			stream.done = ->
				onend = ->
					file.on "close", ->
						fs.rename tmpname, name, (err) ->
							if err
								stream.emit "error", err
							else
								stream.emit "success"

					file.destroySoon()

				if _ended
					onend()
				else
					stream.on "end", onend

			stream.abort = ->
				if opened
					opened = false
					file.on "close", ->
						fs.unlink tmpname, ->

				file.destroySoon()

			file.on "open", ->
				opened = true
				
				# re-emitting open because it's handled in storage.js
				stream.emit "open"

			file.on "error", (err) ->
				stream.emit "error", err

		return stream

	###*
	 * [write_json description]
	 * @param  {[type]}   name
	 * @param  {[type]}   value
	 * @param  {Function} cb
	 * @return {[type]}
	###
	write_json: (name, value, cb) ->
		@write name, JSON.stringify(value, null, "\t"), cb

	###*
	 * [read_stream description]
	 * @param  {[type]}   name
	 * @param  {[type]}   stream
	 * @param  {Function} callback
	 * @return {[type]}
	###
	read_stream: (name, stream, callback) ->
		rstream = fs.createReadStream(name)
		rstream.on "error", (err) ->
			stream.emit "error", err

		rstream.on "open", (fd) ->
			fs.fstat fd, (err, stats) ->
				return stream.emit("error", err)  if err
				stream.emit "content-length", stats.size
				stream.emit "open"
				rstream.pipe stream

		stream = new mystreams.ReadTarballStream()
		stream.abort = ->
			rstream.close()

		return stream
	###*
	 * [read_json description]
	 * @param  {[type]}   name
	 * @param  {Function} cb
	 * @return {[type]}
	###
	read_json: (name, cb) ->
		@read name, (err, res) ->
			return cb(err)  if err
			args = []
			try
				args = [
					null
					JSON.parse(res.toString("utf8"))
				]
			catch err
				args = [err]
			cb.apply null, args

	###*
	 * [create description]
	 * @param  {[type]}   name
	 * @param  {[type]}   contents
	 * @param  {Function} callback
	 * @return {[type]}
	###
	create: (name, contents, callback) ->
		fs.exists name, (exists) ->
			return callback(FSError("EEXISTS"))  if exists
			write name, contents, callback
	###*
	 * [create_json description]
	 * @param  {[type]}   name
	 * @param  {[type]}   value
	 * @param  {Function} cb
	 * @return {[type]}
	###
	create_json: (name, value, cb) ->
		@create name, JSON.stringify(value, null, "\t"), cb

	###*
	 * [update description]
	 * @param  {[type]}   name
	 * @param  {[type]}   contents
	 * @param  {Function} callback
	 * @return {[type]}
	###
	update: (name, contents, callback) ->
		fs.exists name, (exists) ->
			return callback(FSError("ENOENT"))  unless exists
			write name, contents, callback

	###*
	 * [update_json description]
	 * @param  {[type]}   name
	 * @param  {[type]}   value
	 * @param  {Function} cb
	 * @return {[type]}
	###
	update_json: (name, value, cb) ->
		@update name, JSON.stringify(value, null, "\t"), cb

	###*
	 * open and flock with exponential backoff
	 * @param  {[type]}   name
	 * @param  {[type]}   opmod
	 * @param  {[type]}   flmod
	 * @param  {[type]}   tries
	 * @param  {[type]}   backoff
	 * @param  {Function} cb
	 * @return {[type]}
	###
	open_flock: (name, opmod, flmod, tries, backoff, cb) ->
		fs.open name, opmod, (err, fd) ->
			return cb(err, fd)  if err
			fsExt.flock fd, flmod, (err) ->
				if err
					unless tries
						fs.close fd, ->
							cb err

					else
						fs.close fd, ->
							setTimeout (->
								open_flock name, opmod, flmod, tries - 1, backoff * 2, cb
								return
							), backoff

				else
					cb null, fd

	###*
	 * [lock_and_read description]
	# this function neither unlocks file nor closes it
	# it'll have to be done manually later
	 * @param  {[type]} name
	 * @param  {[type]} _callback
	 * @return {[type]}
	###
	lock_and_read = (name, _callback) ->
		open_flock name, "r", "exnb", 4, 10, (err, fd) ->
			callback = (err) ->
				if err and fd
					fs.close fd, (err2) ->
						_callback err

				else
					_callback.apply null, arguments
				return
			return callback(err, fd)  if err
			fs.fstat fd, (err, st) ->
				onRead = (err, bytesRead, buffer) ->
					return callback(err, fd)  if err
					return callback(new Error("st.size != bytesRead"), fd)  unless bytesRead is st.size
					callback null, fd, buffer
				return callback(err, fd)  if err
				buffer = new Buffer(st.size)
				return onRead(null, 0, buffer)  if st.size is 0
				fs.read fd, buffer, 0, st.size, null, onRead

	###*
	 * [lock_and_read_json description]
	 * @param  {[type]}   name
	 * @param  {Function} cb
	 * @return {[type]}
	###
	lock_and_read_json: (name, cb) ->
		@lock_and_read name, (err, fd, res) ->
			return cb(err, fd)  if err
			args = []
			try
				args = [
					null
					fd
					JSON.parse(res.toString("utf8"))
				]
			catch err
				args = [
					err
					fd
				]
			cb.apply null, args


module.exports = LocalStorage