# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'tempfile'
require 'viiite'
require 'stream_logic'


file1 = Tempfile.new('file1')
file2 = Tempfile.new('file2')

arr1 = 100_000.times.map { rand(10_000_000).to_s(36) }.sort
arr2 = 100_000.times.map { rand(10_000_000).to_s(36) }.sort

arr1.each { |n| file1.puts(n) }
arr2.each { |n| file2.puts(n) }

stream1 = StreamLogic::Stream.new(arr1)
stream2 = StreamLogic::Stream.new(arr2)
stream3 = StreamLogic::Stream.new { file1.rewind; file1 }
stream4 = StreamLogic::Stream.new { file2.rewind; file2 }

Viiite.bench do |r|
  r.report('Array stream1 & stream2') do
    (stream1 & stream2).each { |e| }
  end
  r.report('Array stream1 | stream2') do
    (stream1 | stream2).each { |e| }
  end
  r.report('File stream1 & stream2') do
    (stream3 & stream4).each { |e| }
  end
  r.report('File stream1 | stream2') do
    (stream3 | stream4).each { |e| }
  end
end