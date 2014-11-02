require 'mocha'
should = require 'should'
path = require 'path'


describe "RemoteFS", ->

	remotefs = require '../lib/filesystems/remote'
	RemoteFs = new remotefs
		url: 'http://localhost:3000'

	describe 'Fetching Files', ->

		it 'should read existing file'
		it 'should return 404 not found for non-existant file'
		it 'should return meta data about existing files'

	describe 'Writing a file', ->

		it 'should accept a stream'
		it 'should write a new file'
		it 'should not overwrite existing file'
		it 'should append version number to existing file and write new file'
