#global module:false

"use strict"

ebook = require 'underscore-ebook-template'

module.exports = (grunt) ->
  ebook(grunt, { 
    dir: { 
      page     : "target/pages",
      template : "src/templates"
    } 
  })
  return
