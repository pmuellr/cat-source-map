# Licensed under the Apache License. See footer for details.

fs    = require "fs"
path  = require "path"
util  = require "util"

_         = require "underscore"
sourceMap = require "source-map"

pkg = require "../package.json"

PROGRAM = pkg.name
VERSION = pkg.version

csm = exports

#-------------------------------------------------------------------------------
csm.version = VERSION

#-------------------------------------------------------------------------------
DefaultLogger = (message) -> console.log "#{PROGRAM}: #{message}"

#-------------------------------------------------------------------------------
csm.process = (oFile, iFiles, options) ->
    options.log = DefaultLogger unless _.isFunction options.log

    if options.verbose 
        options.logv = options.log 
    else
        options.logv = ->

    try 
        process oFile, iFiles, options
    catch err
        options.log "error: #{err}"
        return e

    return

#-------------------------------------------------------------------------------
process = (oFile, iFiles, options) ->
    
    throw Error "oFile parameter should be a string"  unless _.isString oFile
    throw Error "iFiles parameter should be an array" unless _.isArray iFiles

    iFiles = for iFile in iFiles
        "#{iFile}"

    iFileNames = for iFile in iFiles
        "`#{iFile}`"

    options.logv "oFile:   `#{oFile}`"
    options.logv "iFiles:  #{iFileNames.join ' '}"
    options.logv "options: #{util.inspect options}"

    for iFile in iFiles
        unless fs.existsSync iFile
            throw Error "input file '#{iFile}' not found"

    sFiles = for iFile in iFiles
        getSourceFile iFile

    mFile = "#{oFile}.map.json"

    outSourceMap = sourceMap.SourceMapGenerator
        file: mFile

    for sFile in sFiles
        console.log "woulda done something with a sourceFile"

    "#{outSourceMap}".to mFile
    log "woulda generated #{outName} and #{mapName}"

    for sFile in sFiles 
        log "processing #{srcFile.name}:"

        srcFile.map.sourcesContent ?= []

        index = 0
        for index in [0...srcFile.map.sources.length]
            sourceName    = srcFile.map.sources[index]
            sourceContent = srcFile.map.sourcesContent[index]
            # log "    #{sourceName}"

            # angular - grumble
            #continue if sourceName is "MINERR_ASSET"

            if !sourceContent
                sourceContent = getSourceContent srcFile.name, sourceName

            if !sourceContent?
                log "unable to get source for #{sourceName} from #{srcFile.name}; skipping"
                continue

            sourceName = path.relative process.cwd(), sourceName 

            mapObject.sources.push          sourceName
            mapObject.sourcesContent.push   sourceContent

    try 
        fs.writeFileSync outName, mapObject.sourcesContent.join "\n"
    catch err
        throw "error writing file '#{oFile}`: #{err}"

    try        
        fs.writeFileSync mFile, JSON.stringify mapObject, null, 4
    catch err
        throw "error writing file '#{mFile}`: #{err}"

    options.vlog "generated files #{oFile} and #{mFile}"

    return

#-------------------------------------------------------------------------------
getSourceFile = (fileName) ->
    srcFile = 
        fileName: fileName

    srcFile.content = fs.readFileSync fileName, "utf8"

    srcMap = getSourceMap srcFile









#-------------------------------------------------------------------------------
getSourceMap = (srcFile) ->

    




#-------------------------------------------------------------------------------
getSourceContent = (srcFile, srcName) ->
    dirName  = path.dirname srcFile
    fileName = path.resolve dirName, srcName

    #log "getSourceContent(#{srcFile}, #{srcName})"
    #log "   dirName:  #{dirName}"
    #log "   fileName: #{fileName}"

    return if !fs.existsSync fileName

    return fs.readFileSync fileName, "utf8"

#-------------------------------------------------------------------------------
# for a given file name and content, return an object with the following
# properties:
# 
# * map     - a normalized souce map that includes `sourcesContent`
# * content - the original content with annotations deactivated in place
#-------------------------------------------------------------------------------
# //@ sourceMappingURL=
getSource = (name, content) ->
    content = fs.readFileSync name, "utf8"

    result =
        map:     null
        content: content

    dir = path.dirname name

    pattern = "^//(#|@) sourceMappingURL=(.*)$"
    
    patternSingle = new RegExp pattern, "m"
    patternMulti  = new RegExp pattern, "gm"

    # get the last annotation in the file
    match = content.match patternMulti
    return result if not match 

    last  = _.last match
    match = last.match patternMultiingle
    url   = match[2]

    # if it's a data url, parse it
    match = url.match /data:.*?;base64,(.*)/
    if match
        data = match[1]
        data = new Buffer(data, "base64").toString("utf8")
        result.map = JSON.parse data

    # if it's not a data url, read it
    else
        fullUrl = path.resolve dir, url

        if !fs.existsSync fullUrl
            log "map file '#{url}' for '#{name}' not found; ignoring map"
            return result

        data = fs.readFileSync fullUrl, "utf8"
        data = JSON.parse data
        result.map = data

    # add sourcesContent if not there


    # deactivate out old annotations
    result.content = content.replace patternMulti, "//XXX sourceMappingURL annotation removed"

    return result

#-------------------------------------------------------------------------------
# returns an array of relevant files from the input array of file names
#
# adds the "ext" property to the array which indicates the extension of
# the file to generate
#-------------------------------------------------------------------------------
checkFiles = (files) ->
    result = []

    result.ext = "?"

    for file in files
        if !fs.existsSync file
            log "source file '#{file}' doesn't exist; skipping"
            continue

        ext = path.extname path.basename file
        if ext is ""
            log "source file '#{file}' has no extension; skipping"
            continue

        if ext is ".css"
            result.ext = "css" if result.ext is "?"
            if result.ext isnt "css"
                log "source file '#{file}' is a css file, but processing #{result.ext} files; skipping"
                continue
            
            result.push file
            continue

        if ext is ".js"
            result.ext = "js" if result.ext is "?"
            if result.ext isnt "js"
                log "source file '#{file}' is a js file, but processing #{result.ext} files; skipping"
                continue
            
            result.push file        
            continue
        
        log "source file '#{file}' has an unknown extension '#{ext}'; skipping"

    if result.ext is "?"
        logError "no js or css files specified"
        return

    return result

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
