# Licensed under the Apache License. See footer for details.

path = require "path"

_      = require "underscore"
expect = require "expect.js"

utils = require "./utils"
csm   = require "../lib/cat-source-map"

#-------------------------------------------------------------------------------

describe "CoffeeScript support", ->

    beforeEach ->
        utils.cleanDir "tmp"

    it "should handle a single CoffeeScript file", (done) ->
        iFile = path.join __dirname, "sample_01.coffee"
        utils.coffeec "--output tmp #{iFile}"

        utils.cat_source_map "-v tmp/sample_01.js tmp/sample_01_c.js"
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
