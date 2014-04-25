module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: '<json:package.json>'

    coffee:
      client:
        expand: true
        cwd: "client"
        src: ["**/*.coffee"]
        dest: "public/js"
        ext: ".js"
          
    watch:
      files: [
        'src/**/*.coffee'
      ]
      tasks: ['shell:browserify_app']
    jasmine_node:
      options:
        forceExit: true
        match: '.'
        matchall: false
        extensions: 'coffee'
        specNameMatcher: 'spec'
        jUnit:
          report: true
          savePath : "./build/reports/jasmine/"
          useDotNotation: true
          consolidate: true
      all: ['spec/']

    shell:
      server:
        command: "foreman start"
        options:
          stdout: true

      jasmine:
        command: "node_modules/jasmine-node/bin/jasmine-node --coffee spec/"
        options:
          stdout: true
          failOnError: true

      jasmine_watch:
        command: "node_modules/jasmine-node/bin/jasmine-node --autotest --watch . --coffee spec/"
        options:
          stdout: true

      browserify_app:
        command: "node_modules/.bin/browserify -t coffeeify src/app.coffee > public/js/app.js"
        options:
          failOnError: true
          stdout: true

      sneak_sim_sim:
        command: "cd ../sim-sim-js && grunt build && cd ../bumpercats && rm -rf node_modules/sim-sim-js && cp -r ../sim-sim-js/build ./node_modules/sim-sim-js"
        options:
          failOnError: true
          stdout: true

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-jasmine-node'
  grunt.loadNpmTasks 'grunt-shell'

  grunt.registerTask 'spec', ['jasmine_node']

  grunt.registerTask 'server', 'shell:server'
  grunt.registerTask 'test', 'shell:jasmine'
  grunt.registerTask 'wtest', 'shell:jasmine_watch'

  grunt.registerTask 'bundle', ['shell:browserify_app']
  grunt.registerTask 'simsim', ['shell:sneak_sim_sim']
