path = require "path"

sample_02 = require "./sample_02"

exports.sample_01 = ->
    console.log "->sample_01"
    sample_02.sample_02()
    console.log "<-sample_01"    

exports.sample_01() if require.main is module