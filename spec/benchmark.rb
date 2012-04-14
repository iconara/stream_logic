# encoding: utf-8

$: << File.expand_path('../../lib', __FILE__)

require 'tempfile'
require 'viiite'
require 'stream_logic'


N = 100_000

def random_list_of_numbers!
  N.times.map { rand(10_000_000).to_s(36) }.sort
end

file1 = Tempfile.new('file1')
file2 = Tempfile.new('file2')

random_list_of_numbers!.each { |n| file1.puts(n) }
random_list_of_numbers!.each { |n| file2.puts(n) }

Viiite.bench do |r|
  r.range_over(['Array', 'File', 'Expressions'], :type) do |type|
    case type
    when 'Array'
      a = StreamLogic::Stream.new(random_list_of_numbers!)
      b = StreamLogic::Stream.new(random_list_of_numbers!)
    when 'File'
      a = StreamLogic::Stream.new { file1.rewind; file1 }
      b = StreamLogic::Stream.new { file2.rewind; file2 }
    when 'Expressions'
      a = StreamLogic::Stream.new(random_list_of_numbers!)
      b = StreamLogic::Stream.new(random_list_of_numbers!)
      c = StreamLogic::Stream.new(random_list_of_numbers!)
      d = StreamLogic::Stream.new(random_list_of_numbers!)
      e = StreamLogic::Stream.new(random_list_of_numbers!)
      f = StreamLogic::Stream.new(random_list_of_numbers!)
      complex_expr = (a & b & c) | (d & e & f)
      simple_expr = complex_expr.simplify
    end

    case type
    when 'Array', 'File'
      r.report('a & b') do
        (a & b).to_a
      end

      r.report('a | b') do
        (b | a).to_a
      end

      r.report('a + b') do
        (b + a).to_a
      end

      r.report('a - b') do
        (b - a).to_a
      end
    when 'Expressions'
      r.report('((a & b) & c) | ((d & e) & f)') do
        complex_expr.to_a
      end

      r.report('(a & b & c) | (d & e & f)') do
        simple_expr.to_a
      end
    end
  end
end