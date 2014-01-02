# Licensed under the Apache License. See footer for details.

fs   = require "fs"
path = require "path"

nopt = require "nopt"

pkg  = require "../package.json"
csm  = require "./cat-source-map"

PROGRAM = pkg.name
VERSION = pkg.version

cli = exports

#-------------------------------------------------------------------------------
exports.main = ->

    options =
        verbose: Boolean
        help:    Boolean

    shortOptions =
        v:   ["--verbose"]
        h:   ["--help"]
        "?": ["--help"]

    parsed = nopt options, shortOptions, process.argv, 2

    args = parsed.argv.remain

    return help() if args.length is 0
    return help() if args[0] in ["?", "help"]
    return help() if parsed.help

    options = {}
    options.verbose = parsed.verbose if parsed.verbose?

    oFile  = args.pop()
    iFiles = args

    err = csm.processFiles oFile, iFiles, options

    return 1 if err?
    return 0

#-------------------------------------------------------------------------------
help = ->
    console.log """
        #{PROGRAM} #{VERSION}

            concatenate JavaScript files, handling source map bits

        usage: #{PROGRAM} [options] srcFile1 srcFile2 ... outFile

            options:
                --verbose -v   be verbose
                --help    -h   print this help

        Output files ${outFile} and ${outFile}.map.json will be generated by
        concatenating the source files into the outFile, and recalculating the
        source maps into the .map.json outFile.
    """

    return

#-------------------------------------------------------------------------------
exports.main() if require.main is module

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
