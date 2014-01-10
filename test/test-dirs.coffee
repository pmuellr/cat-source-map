# Licensed under the Apache License. See footer for details.

path = require "path"

_      = require "underscore"
expect = require "expect.js"

utils = require "./utils"
csm   = require "../lib/cat-source-map"

testName = (path.basename __filename).split(".")[0]
testDir  = path.join "tmp", testName

#-------------------------------------------------------------------------------

describe "directory support", ->

    before ->
        utils.cleanDir testDir
        cd testDir
        mkdir "-p", "src"
        cp "../../*sample*", "src"

    after ->
        cd "../.."

    it "should handle one JavaScript files in a subdirectory", (done) ->
        utils.coffeec "src/sample_01.coffee"

        utils.cat_source_map "src/sample_01.js src/sample_01_c.js"

        cp "src/sample_01_c.js.map.json", "."
        cmp = utils.compareMaps testName, "sample_01_c"
        expect(cmp).to.be true

        done()

    it "should handle two CoffeeScript files in a subdirectory", (done) ->
        utils.coffeec "--map src/sample_01.coffee"
        utils.coffeec "--map src/sample_02.coffee"

        utils.cat_source_map "src/sample_01.js src/sample_02.js src/sample_01_02_c.js"

        cp "src/sample_01_02_c.js.map.json", "."
        cmp = utils.compareMaps testName, "sample_01_02_c"
        expect(cmp).to.be true

        done()

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
