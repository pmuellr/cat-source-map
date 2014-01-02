# Licensed under the Apache License. See footer for details.

fs   = require "fs"
path = require "path"

require "shelljs/global"

lib          = path.resolve path.join __dirname, "..", "lib"
node_modules = path.resolve path.join __dirname, "..", "node_modules"

mkdir "-p", path.join(__dirname, "..", "tmp")

#-------------------------------------------------------------------------------
node_modules_bin = (cmd) ->
    path.join node_modules, ".bin", cmd

#-------------------------------------------------------------------------------
exports.coffee = (cmd) ->
    cmd = normalizeCommand cmd
    exec "node #{node_modules_bin "coffee"} #{cmd}"

#-------------------------------------------------------------------------------
exports.coffeec = (cmd) ->
    cmd = normalizeCommand cmd
    exports.coffee "--compile --bare #{cmd}"

#-------------------------------------------------------------------------------
exports.browserify = (cmd) ->
    cmd = normalizeCommand cmd
    exec "node #{node_modules_bin "browserify"} #{cmd}"

#-------------------------------------------------------------------------------
exports.uglifyjs = (cmd) ->
    cmd = normalizeCommand cmd
    exec "node #{node_modules_bin "uglifyjs"} #{cmd}"

#-------------------------------------------------------------------------------
exports.cat_source_map = (cmd) ->
    exec "node #{path.join lib, "cli.js"} #{cmd}"

#-------------------------------------------------------------------------------
exports.cleanDir = (dir) ->
    mkdir "-p",  dir
    rm    "-rf", path.join(dir, "*")

#-------------------------------------------------------------------------------
exports.compareMaps = (testName, baseFile) ->
    actualFile   = "#{baseFile}.js.map.json"
    expectedFile = path.join "..", "..", "expected", testName, actualFile

    actualContents   = fs.readFileSync actualFile,   "utf8"
    expectedContents = fs.readFileSync expectedFile, "utf8"

    return actualContents == expectedContents

#-------------------------------------------------------------------------------
normalizeCommand = (cmd) ->
    cmd.replace(/\s+/g," ").trim()


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
