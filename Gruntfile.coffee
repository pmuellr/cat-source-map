# Licensed under the Apache License. See footer for details.

fs            = require "fs"
path          = require "path"

require "shelljs/global"
_ = require "underscore"

process.setMaxListeners(0)

#-------------------------------------------------------------------------------

module.exports = (grunt) ->

    grunt.initConfig

        watch: [
            "lib-src"
        ]

        clean: [
            "lib"
            "node_modules"
            "tmp"
        ]

    #----------------------------------

    grunt.registerTask "default", ["help"]

    grunt.registerTask "help", "Display available commands", ->
        exec "grunt --help", @async()

    grunt.registerTask "build", "Build the server", ->
        runBuild grunt, @

    grunt.registerTask "test", "Run the tests", ->
        runTests grunt, @

    grunt.registerTask "watch", "When src files change, re-build and re-test", ->
        @async()
        runWatch grunt

    grunt.registerTask "clean", "Remove generated files", ->
        runClean grunt, @

#-------------------------------------------------------------------------------

runBuild = (grunt, task) ->
    makeWriteable grunt, task
    runBuildMeat  grunt, task
    makeReadOnly  grunt, task

#-------------------------------------------------------------------------------

runBuildMeat = (grunt, task) ->

    timeStart = Date.now()

    mkdir "-p",  "lib"
    rm    "-rf", "lib/*"

    coffeec "--output lib lib-src/*.coffee"

    timeElapsed = Date.now() - timeStart
    log grunt, "build time: #{timeElapsed/1000} sec"

    return

#-------------------------------------------------------------------------------

runTests = (grunt) ->
    log grunt, "woulda run tests here"

    return

#-------------------------------------------------------------------------------
runWatch = (grunt, fileName=null, watchers=[]) ->
    return if watchers.tripped

    if fileName
        log grunt, "----------------------------------------------------"
        log grunt, "file changed: #{fileName}" 

    if watchers.length
        for watcher in watchers
            fs.unwatchFile watcher

        watchers.splice 0, watchers.length
        watchers.tripped = true

    runBuild grunt
    runTests grunt

    watchFiles = []
    watchDirs  = grunt.config "watch"

    for dir in watchDirs
        files = ls "-RA", dir
        files = _.map files, (file) -> path.join dir, file

        watchFiles = watchFiles.concat files

    watchers = []
    watchers.tripped = false

    options = 
        persistent: true
        interval:   500

    for watchFile in watchFiles
        watchHandler = getWatchHandler grunt, watchFile, watchers
        fs.watchFile watchFile, options, watchHandler

        watchers.push watchFile

    fs.watchFile __filename, options, ->
        log grunt, "#{path.basename __filename} changed; exiting"
        process.exit 0
        return

    log grunt, "watching #{1 + watchFiles.length} files for changes"

    return

#-------------------------------------------------------------------------------
getTime =  ->
    date = new Date()
    hh   = align.right date.getHours(),   2, 0
    mm   = align.right date.getMinutes(), 2, 0

    return "#{hh}:#{mm}"

#-------------------------------------------------------------------------------
log =  (grunt, message) ->
    grunt.log.writeln "#{getTime()} - #{message}"

#-------------------------------------------------------------------------------
getWatchHandler = (grunt, watchFile, watchers) ->
    return (curr, prev) ->
        return if curr.mtime == prev.mtime

        runWatch grunt, watchFile, watchers

        return

#-------------------------------------------------------------------------------

runClean = (grunt) ->
    dirs = grunt.config "clean"

    makeWritable()

    for dir in dirs
        if test "-d", dir
            rm "-rf", dir

    return

#-------------------------------------------------------------------------------
align = (s, direction, length, pad=" ") ->
    s   = "#{s}"
    pad = "#{pad}"

    direction = direction.toUpperCase()[0]

    if direction is "L"
        doPad = (s) -> s + pad
    else if direction is "R"
        doPad = (s) -> pad + s
    else
        throw Error "invalid direction argument for align()"

    while s.length < length
        s = doPad s

    return s

align.right = (s, length, pad=" ") -> align s, "right", length, pad
align.left  = (s, length, pad=" ") -> align s, "left",  length, pad


#-------------------------------------------------------------------------------

coffee = (command) ->
    exec "node_modules/.bin/coffee #{command}"
    return

#-------------------------------------------------------------------------------

coffeec = (command) ->
    exec "node_modules/.bin/coffee --bare --compile #{command}"
    return

#-------------------------------------------------------------------------------

makeWriteable = ->
    mkdir "-p", "www", "lib"
    chmod "-R", "+w", "www"
    chmod "-R", "+w", "lib"

    return

#-------------------------------------------------------------------------------

makeReadOnly = ->
    mkdir "-p", "www", "lib"
    chmod "-R", "-w", "www"
    chmod "-R", "-w", "lib"

    return

#-------------------------------------------------------------------------------
# Copyright 2013 Patrick Mueller
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------
