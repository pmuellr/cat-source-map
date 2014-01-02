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
csm.processFiles = (oFile, iFiles, options) ->
    options.log = DefaultLogger unless _.isFunction options.log

    if options.verbose
        options.logv = options.log
    else
        options.logv = ->

    try
        processFiles oFile, iFiles, options
    catch err
        options.log "error: #{err}"
        options.log "stack:\n#{err.stack}"
        return err

    return

#-------------------------------------------------------------------------------
processFiles = (oFile, iFiles, options) ->

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

    srcFiles = for iFile in iFiles
        getSourceFile iFile, options

    mapFile = "#{oFile}.map.json"

    outSourceNode = new sourceMap.SourceNode null, null, null

    for srcFile in srcFiles
        options.logv "processing `#{srcFile.fileName}`"

        sourceNode = sourceMap.SourceNode.fromStringWithSourceMap srcFile.content, srcFile.smc
        outSourceNode.add sourceNode
        outSourceNode.setSourceContent srcFile.fileName, srcFile.content

    gen = outSourceNode.toStringWithSourceMap {file: oFile}

    map = JSON.stringify JSON.parse(gen.map.toString()), null, 4

    code = """
        #{gen.code}
        //# sourceMappingURL=#{path.basename mapFile}
    """

    fs.writeFileSync oFile,   code
    fs.writeFileSync mapFile, map

    options.logv "generated files `#{oFile}` and `#{mapFile}`"

    return

#-------------------------------------------------------------------------------
getSourceFile = (fileName, options) ->
    srcFile = {}
    srcFile.fileName = fileName
    srcFile.content  = fs.readFileSync fileName, "utf8"
    srcFile.smc      = getSourceMapConsumer srcFile, options

    return srcFile

#-------------------------------------------------------------------------------
getSourceMapConsumer = (srcFile, options) ->
    pattern = "^//(#|@) sourceMappingURL=(.*)$"

    patternSingle = new RegExp pattern, "m"
    patternMulti  = new RegExp pattern, "gm"

    # get annotations in the file
    match = srcFile.content.match patternMulti
    return getIdentitySourceMapConsumer srcFile, options if not match

    # get the last annotation
    last  = _.last match
    match = last.match patternSingle
    url   = match[2]

    # deactivate out old annotations
    srcFile.content = srcFile.content.replace patternMulti, "// sourceMappingURL annotation removed"

    # if it's a data url, parse it
    match = url.match /data:.*?;base64,(.*)/
    if match
        data = match[1]
        data = new Buffer(data, "base64").toString("utf8")
        data = JSON.parse data

        fullUrl = srcFile.fileName

    # if it's not a data url, read it
    else
        dir     = path.dirname srcFile.fileName
        fullUrl = path.relative dir, url

        if !fs.existsSync fullUrl
            options.log "map file '#{url}' for '#{name}' not found; ignoring map"
            return getIdentitySourceMapConsumer srcFile, options

        data = fs.readFileSync fullUrl, "utf8"
        data = JSON.parse data

    unless data.sourcesContent
        data.sourcesContent = []
        basePath = path.dirname fullUrl
        if data.sourceRoot and data.sourceRoot isnt ""
            basePath = path.relative basePath, data.sourceRoot

        for source in data.sources
            sourceFileName = path.relative basePath, source
            if !fs.existsSync sourceFileName
                options.log "unable to find source file '#{sourceFileName}'; ignoring map"
                return getIdentitySourceMapConsumer srcFile, options

            sourceFileContent = fs.readFileSync sourceFileName, "utf8"
            data.sourcesContent.push sourceFileContent

    for i in [0...data.sources.length]
        if data.sources[i][0] is "/"
            data.sources[i] = path.relative process.cwd(), data.sources[i]

    return new sourceMap.SourceMapConsumer data

#-------------------------------------------------------------------------------
getIdentitySourceMapConsumer = (srcFile, options) ->
    smg = new sourceMap.SourceMapGenerator
        file: srcFile.fileName

    lines = srcFile.content.split("\n").length

    line = 0
    while line < lines
        line++

        smg.addMapping
            source:       srcFile.fileName
            original:     { line: line, column: 0 }
            generated:    { line: line, column: 0 }

    return new sourceMap.SourceMapConsumer smg.toString()

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
