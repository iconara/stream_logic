require_relative '../spec_helper'

require 'tempfile'


module StreamLogic
  describe Stream do
    it 'returns a stream with each item in an enumerable' do
      described_class.new { %w[a b c] }.to_a.should == %w[a b c]
    end

    describe '#&' do
      it 'returns a stream with items that exist in all enumerables' do
        s1 = described_class.new(%w[a c m q])
        s2 = described_class.new(%w[c m])
        s3 = described_class.new(%w[c l m n x z])
        s4 = described_class.new(%w[b c m w z])
        (s1 & s2 & s3 & s4).to_a.should == %w[c m]
      end

      it 'returns only distinct elements' do
        s1 = described_class.new(%w[a a a a a b b])
        s2 = described_class.new(%w[a b b b c c])
        (s1 & s2).to_a.should == %w[a b]
      end

      it 'handles an edge case' do
        s1 = described_class.new(%w[  c d e])
        s2 = described_class.new(%w[a c d  ])
        s3 = described_class.new(%w[a   d e])
        (s1 & s2 & s3).simplify.to_a.should == %w[d]
      end
    end

    describe '#|' do
      it 'returns a stream with items that exist in any of the enumerables' do
        s1 = described_class.new(%w[a c m q])
        s2 = described_class.new(%w[c m])
        s3 = described_class.new(%w[c l m n x z])
        s4 = described_class.new(%w[b c m w z])
        (s1 | s2 | s3 | s4).to_a.should == %w[a b c l m n q w x z]
      end

      it 'returns only distinct elements' do
        s1 = described_class.new(%w[a a a a a b b])
        s2 = described_class.new(%w[a b b b c c])
        (s1 | s2).to_a.should == %w[a b c]
      end
    end

    describe '#+' do
      it 'returns a stream with all the items of all the streams' do
        s1 = described_class.new(%w[a   c   m   q      ])
        s2 = described_class.new(%w[    c   m          ])
        s3 = described_class.new(%w[    c l m n     x z])
        s4 = described_class.new(%w[  b c   m     w z  ])
        (s1 + s2 + s3 + s4).to_a.should == %w[a b c c c c l m m m m n q w x z z]
      end
    end

    describe '#-' do
      it 'returns a stream with items that exist only in one of the streams' do
        s1 = described_class.new(%w[a   c   m   q      ])
        s2 = described_class.new(%w[    c   m          ])
        s3 = described_class.new(%w[    c l m n     x z])
        s4 = described_class.new(%w[  b c   m     w   z])
        (s1 - s2 - s3 - s4).to_a.should == %w[a b l n q w x]
      end
    end

    describe '#simplify' do
      before do
        @s1 = Stream.new([1, 2, 3, 4])
        @s2 = Stream.new([2, 3, 4, 5])
        @s3 = Stream.new([3, 4, 5, 6])
        @s4 = Stream.new([4, 5, 6, 7])
        @s5 = Stream.new([5, 6, 7, 8])
        @s6 = Stream.new([6, 7, 8, 9])
      end

      it 'simplifies complex expressions' do
        expr = (@s1 & @s2 & @s3) | (@s4 & @s5 & @s6)
        expr.simplify.subqueries.first.subqueries.should have(3).items
        expr.simplify.to_a.should == expr.to_a
      end

      it 'is aliased as #normalize' do
        expr = (@s1 & @s2 & @s3) | (@s4 & @s5 & @s6)
        expr.normalize.subqueries.first.subqueries.should have(3).items
        expr.normalize.to_a.should == expr.to_a
      end
    end

    it 'returns a stream with the result of complex logical expressions on other streams' do
      s1 = described_class.new(%w[a c m q])
      s2 = described_class.new(%w[c m])
      s3 = described_class.new(%w[c l m n x z])
      s4 = described_class.new(%w[b c m w z])
      ((s1 | s2 | s3) & s4).to_a.should == %w[c m z]
    end

    it 'let\'s you pass custom enumerator initialization logic' do
      f1 = Tempfile.new('f1')
      10.times { |i| f1.puts(i) }
      s1 = described_class.new { f1.rewind; f1 }
      s1.to_a.should have(10).items
      s1.to_a.should have(10).items
    end

    it 'works with IO objects' do
      f1 = Tempfile.new('f1')
      f2 = Tempfile.new('f2')
      f3 = Tempfile.new('f3')
      f4 = Tempfile.new('f4')
      %w[a c m q].each { |x| f1.puts(x) }
      %w[c m].each { |x| f2.puts(x) }
      %w[c l m n x z].each { |x| f3.puts(x) }
      %w[b c m w z].each { |x| f4.puts(x) }
      s1 = described_class.new { f1.rewind; f1 }
      s2 = described_class.new { f2.rewind; f2 }
      s3 = described_class.new { f3.rewind; f3 }
      s4 = described_class.new { f4.rewind; f4 }
      ((s1 | s2 | s3) & s4).to_a.map(&:chomp).should == %w[c m z]
    end

    it 'automatically rewinds streams' do
      s1 = described_class.new(%w[a c m q])
      s2 = described_class.new(%w[c m])
      s3 = described_class.new(%w[c l m n x z])
      s4 = described_class.new(%w[b c m w z])
      (s1 | s2 | s3 | s4).to_a.should == %w[a b c l m n q w x z]
      (s1 | s2 | s3 | s4).to_a.should == %w[a b c l m n q w x z]
    end

    it 'evaluates the combined stream lazily' do
      s1 = described_class.new do
        Enumerator.new do |yielder|
          yielder << 0
          yielder << 100
        end
      end
      s2 = described_class.new do
        Enumerator.new do |yielder|
          counter = 3
          loop do
            yielder << counter
            counter += 3
          end
        end
      end
      s3 = described_class.new do
        Enumerator.new do |yielder|
          counter = 5
          loop do
            yielder << counter
            counter += 5
          end
        end
      end
      (s1 | (s2 & s3)).take(10).should == [0, 15, 30, 45, 60, 75, 90, 100, 105, 120]
    end
  end
end