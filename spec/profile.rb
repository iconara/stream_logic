# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'tempfile'
require 'viiite'
require 'stream_logic'


arr1 = 100_000.times.map { rand(10_000_000).to_s(36) }.sort
arr2 = 100_000.times.map { rand(10_000_000).to_s(36) }.sort

stream1 = StreamLogic::Stream.new(arr1)
stream2 = StreamLogic::Stream.new(arr2)

10.times do
  (stream1 & stream2).each { |e| }
  (stream1 | stream2).each { |e| }
end
