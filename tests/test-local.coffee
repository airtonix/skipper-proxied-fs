require 'mocha'
should = require 'should'
path = require 'path'

describe "LocalFS", ->

	localfs = require '../lib/filesystems/local'
	LocalFS = new localfs
		name: 'main'
		root: path.resolve(__dirname, './fixtures/local')

	describe "Fetching files", ->

		it 'should read existing files', (done) ->
			LocalFS.read 'existing.file.txt', (err, contents) ->
				throw err if err
				should.exist contents
				contents.toString().should.equal 'hello'
				done()

		it 'should return file-not-found for non existant files', (done) ->
			LocalFS.read 'non-existant-file.txt', (err, contents) ->
				throw err if err
				should.not.exist contents
				done()

		it 'should return a list of files', (done) ->
			LocalFS.ls '/', (err, files) ->
				throw err if err
				should.exist files
				files.should.be.an.Array
				done()

	describe "Writing a file", ->

		it 'should write a new file'
		it 'should not overwrite existing file'
		it 'should append version number to existing file and write new file'

	describe "Removing a file", ->

		it 'should remove existing file'
