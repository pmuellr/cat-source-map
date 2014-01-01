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
        options.log "stack:\n#{err.stack}"
        return err

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
        //# sourceMappingURL=#{mapFile}
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
        return new sourceMap.SourceMapConsumer data

    # if it's not a data url, read it
    else
        fullUrl = path.resolve dir, url

        if !fs.existsSync fullUrl
            options.log "map file '#{url}' for '#{name}' not found; ignoring map"
            return getIdentitySourceMap srcFile

        data = fs.readFileSync fullUrl, "utf8"
        data = JSON.parse data
        return new sourceMap.SourceMapConsumer data

#-------------------------------------------------------------------------------
getIdentitySourceMapConsumer = (srcFile, options) ->
    smg = new sourceMap.SourceMapGenerator
        file: srcFile.fileName

    smg.addMapping
      source:       srcFile.fileName
      original:     { line: 1, column: 0 }
      generated:    { line: 1, column: 0 }

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
