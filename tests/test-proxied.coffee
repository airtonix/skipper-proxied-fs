require 'mocha'
should = require 'should'
path = require 'path'


describe "ProxiedFS", ->
	# localfs = require '../lib/filesystems/local'
	# remotefs = require '../lib/filesystems/remote'
	# proxedfs = require '../lib/filesystems/proxied'

	# ProxiedNpmJs = new proxiedfs
	# 	local:
	# 		silos:
	# 			'mine-*':
	# 				path: './storage/mine'

	# 	upstream:
	# 		class: UpstreamFS
	# 		silos:
	# 			'npmjs':
	# 				url: 'http://registry.npmjs.org'

	describe 'Setup', ->

		it 'should create a localfs for each local silo'
		it 'should create a remotefs for each upstream silo'

	describe 'Fetching Files', ->

		it 'should find local file in local silos'
		it 'should find non existant local file in remote silos'
		it 'should cache non existant local file in correct local silo'

