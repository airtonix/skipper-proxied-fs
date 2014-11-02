
class FileSystemBase
	###*
	 * Remove a File
	 * @param  {[type]}   file_descripter
	 * @param  {Function} callback
	 * @return {[type]}
	###
	rm: (file_descripter, callback) ->
		throw new Error 'Not implemented'

	###*
	 * List Files in a directory
	 * @param  {[type]}   dirname
	 * @param  {Function} callback
	 * @return {[type]}
	###
	ls: (dirname, callback) ->
		throw new Error 'Not implemented'

	###*
	 * Read a File
	 * @param  {[type]}   file_descripter
	 * @param  {Function} callback
	 * @return {[type]}
	###
	read: (file_descripter, callback) ->
		throw new Error 'Not implemented'

	###*
	 * Write a file
	 * @param  {[type]} options
	 * @return {[type]}
	###
	recieve: (options) ->
		throw new Error 'Not implemented'

module.exports = FileSystemBase
