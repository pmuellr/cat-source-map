# Licensed under the Apache License. See footer for details.

path = require "path"

_      = require "underscore"
expect = require "expect.js"

utils = require "./utils"
csm   = require "../lib/cat-source-map"

testName = (path.basename __filename).split(".")[0]
testDir  = path.join "tmp", testName

#-------------------------------------------------------------------------------

describe "Uglify support", ->

    before ->
        utils.cleanDir testDir
        cd testDir
        cp "../../*sample*", "."

    after ->
        cd "../.."

    it "should handle uglifying a browserified thing", (done) ->
        utils.coffeec "sample_01.coffee"
        utils.coffeec "sample_02.coffee"

        utils.browserify """
            sample_01.js sample_02.js --debug --outfile sample_01_02_b.js
            """

        utils.cat_source_map "sample_01_02_b.js sample_01_02_c1.js"

        utils.uglifyjs """
            sample_01_02_c1.js
            --in-source-map sample_01_02_c1.js.map.json
            --output        sample_01_02_c2.js
            --source-map    sample_01_02_c2.js.map.json
            """

        utils.cat_source_map "--fixFileNames sample_01_02_c2.js sample_01_02_c.js"

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
