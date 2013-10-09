# Licensed under the Apache License. See footer for details.

fs            = require "fs"
path          = require "path"

_ = require "underscore"

PROGRAM = path.basename(__filename).split(".")[0]

#-------------------------------------------------------------------------------
main = (outBaseName, srcFiles...) ->

    if !outBaseName? or _.isEmpty srcFiles
        help()

    srcFiles = checkFiles srcFiles
    ext      = srcFiles.ext

    outName = "#{outBaseName}.#{ext}"
    mapName = "#{outName}.map.json"

    log "woulda generated #{outName} and #{mapName}"

    try 
        srcFiles = for srcFile in srcFiles 
            buildSrcFile srcFile
    catch err
        logError "exception processing source files: #{err}"

    mapObject = 
        version:        3
        builtOn:        new Date()
        builtBy:        PROGRAM
        file:           outName
        sources:        []
        sourcesContent: []
        names:          []
        mappings:       ""

    for srcFile in srcFiles 
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
        logError "writing to file #{outName}: #{err}"

    try        
        fs.writeFileSync mapName, JSON.stringify mapObject, null, 4
    catch err
        logError "writing to file #{mapName}: #{err}"

    log "generated files #{outName} and #{mapName}"

    return

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
buildSrcFile = (srcFileName) ->
    srcFile = 
        name:    srcFileName
        content: fs.readFileSync srcFileName, "utf8"

    getSourceMappingURL srcFile

    return srcFile

#-------------------------------------------------------------------------------
# //@ sourceMappingURL=
getSourceMappingURL = (srcFile) ->
    {name, content} = srcFile

    dir = path.dirname name

    patternS = "^//(#|@) sourceMappingURL=(.*)$"
    
    patternG = new RegExp patternS, "m"
    patternS = new RegExp patternS, "gm"

    match = content.match patternS
    return if not match 

    last = _.last match

    match = last.match patternG
    return if not match

    url = match[2]

    match = url.match /data:.*?;base64,(.*)/

    if match
        data = match[1]
        data = new Buffer(data, "base64").toString("utf8")
        data = JSON.parse data

        srcFile.map = data

    else
        fullUrl = path.resolve dir, url

        if !fs.existsSync fullUrl
            log "map file '#{url}' for '#{name}' not found; ignored"
            return

        data = fs.readFileSync fullUrl, "utf8"
        data = JSON.parse data
        srcFile.map = data

    # comment out old annotations
    srcFile.content = content.replace  patternS, "//XXX sourceMappingURL annotation removed"

    return

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
log = (message) ->
    console.log "#{PROGRAM}: #{message}"
    return

#-------------------------------------------------------------------------------
logError = (message) ->
    console.log "#{PROGRAM}: error: #{message}"
    process.exit 1
    return

#-------------------------------------------------------------------------------
help = ->
    console.log """
        usage: #{PROGRAM} outFile srcFile1 srcFile2 ...

        concatenate source files, taking into account sourcemaps

        Output files ${outFile}.js and ${outFile}.js.map.json will
        be generated by concatenating the source files into the .js file,
        and recalculating the sourcemaps into the .js.map.json file.
    """

    process.exit 0

#-------------------------------------------------------------------------------
main.apply null, (process.argv.slice 2) if require.main is module

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
