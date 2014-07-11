#global module:false

"use strict"

module.exports = (grunt) ->
  grunt.loadNpmTasks "grunt-contrib-connect"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-exec"

  grunt.initConfig
    less:
      screen:
        options:
          paths: [
            "bower_components/bootstrap/less"
            "src/css"
          ]
          yuicompress: true
        files:
          "essential-scalaz/css/screen.css": "src/css/screen.less"
          "essential-scalaz/css/print.css" : "src/css/print.less"

    uglify:
      site:
        files:
          "essential-scalaz/js/site.js": [
            "bower_components/jquery/jquery.js"
            "bower_components/bootstrap/js/collapse.js"
            "bower_components/bootstrap/js/scrollspy.js"
            "bower_components/bootstrap/js/button.js"
            "bower_components/bootstrap/js/affix.js"
            "bower_components/respond/respond.src.js"
            "src/js/site.js"
          ]

    copy:
      bootstrap:
        files: [{
          expand: true
          cwd: "bower_components/bootstrap/img/"
          src: ["**"]
          dest: "essential-scalaz/images/"
        }]
      images:
        files: [{
          expand: true
          cwd: "src/images"
          src: ["**"]
          dest: "essential-scalaz/images/"
        }]

    exec:
      install:
        cmd: "bundle install"
      jekyll:
        cmd: "bundle exec jekyll build --trace --config jekyll_config.yml"
      deploy:
        cmd: 'echo "Deployment not implemented. Search for this text in gruntfile.coffee and replace it with your own deployment command."'

    bower:
      install: {}

    watch:
      options:
        livereload: true
      css:
        files: [
          "src/css/**/*"
        ]
        tasks: [
          "less"
          "exec:jekyll"
        ]
      js:
        files: [
          "src/js/**/*"
        ]
        tasks: [
          "uglify"
          "exec:jekyll"
        ]
      html:
        files: [
          "src/pages/**/*"
          "src/layouts/**/*"
          "src/includes/**/*"
          "src/posts/**/*"
          "jekyll_plugins/**/*"
          "jekyll_config.yml"
        ]
        tasks: [
          "copy"
          "exec:jekyll"
        ]

    connect:
      server:
        options:
          port: 4000
          base: 'essential-scalaz'

  grunt.registerTask "build", [
    "less"
    "uglify"
    "copy"
    "exec:jekyll"
  ]

  grunt.registerTask "serve", [
    "build"
    "connect:server"
    "watch"
  ]

  grunt.registerTask "deploy", [
    "build"
    "exec:deploy"
  ]

  grunt.registerTask "default", [
    "serve"
  ]
