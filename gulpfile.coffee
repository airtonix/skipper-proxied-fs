gulp = require 'gulp'
mocha = require 'gulp-mocha'

gulp.task 'test', () ->

  gulp.src ['./tests/test-*.*'], read: false
    .pipe mocha
      ui: 'bdd'
      reporter: 'spec'
      compilers: 'coffee:coffee-script'
      globals:
        should: require('should')

gulp.task 'watch', () ->
	gulp.watch [
		'lib/**',
		'tests/***'
	], ['test']


gulp.task 'default', ['test', 'watch']