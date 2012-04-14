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

Viiite.bench do |r|
  n = 1

  r.range_over(['Array', 'File'], :type) do |type|
    case type
    when 'Array'
      a = StreamLogic::Stream.new(arr1)
      b = StreamLogic::Stream.new(arr2)
    when 'File'
      a = StreamLogic::Stream.new { file1.rewind; file1 }
      b = StreamLogic::Stream.new { file2.rewind; file2 }
    end

    r.report('a & b') do
      n.times { (a & b).to_a }
    end
    r.report('a | b') do
      n.times { (b | a).to_a }
    end
  end
end