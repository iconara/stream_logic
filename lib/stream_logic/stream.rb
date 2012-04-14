# encoding: utf-8

module StreamLogic
  module CombinationOperators
    def &(stream)
      AndStream.new(self, stream)
    end

    def |(stream)
      OrStream.new(self, stream)
    end

    def +(stream)
      PlusStream.new(self, stream)
    end

    def -(stream)
      MinusStream.new(self, stream)
    end
  end

  class Stream
    include ExternalEnumeration
    include CombinationOperators

    def initialize(enumerable=nil, &block)
      @enumerable = enumerable
      @constructor = block
    end

    def next_element
      @enumerator ||= adapt(@enumerable ? @enumerable : @constructor.call)
      @enumerator.next_element
    end

    def rewind
      @enumerator = nil
    end

    def to_s
      "Stream[#{(@enumerable ? @enumerable : @constructor).class}]"
    end

    private

    def adapt(enumerable)
      if enumerable.respond_to?(:next_element)
        enumerable
      elsif enumerable.respond_to?(:gets)
        # for Tempfile
        IoEnumerator.new(enumerable)
      else
        case enumerable
        when Array then ArrayEnumerator.new(enumerable)
        when Hash  then ArrayEnumerator.new(enumerable.to_a)
        when IO    then IoEnumerator.new(enumerable)
        else            EnumeratorEnumerator.new(enumerable.to_enum)
        end
      end
    end
  end

  class CombiningStream
    include ExternalEnumeration
    include CombinationOperators

    attr_reader :subqueries

    def initialize(*subqueries)
      @subqueries = subqueries
    end

    def next_element
      @enumerator ||= combination(@subqueries)
      @enumerator.next_element
    end

    def rewind
      @enumerator = nil
    end

    def simplify
      new_subqueries = @subqueries.flat_map do |s|
        if s.class == self.class
          s.simplify.subqueries
        elsif s.respond_to?(:simplify)
          s.simplify
        else
          s
        end
      end
      self.class.new(*new_subqueries)
    end
    alias_method :normalize, :simplify

    def combination
      raise NotImplementedError, %(#combination not implemented!)
    end

    def to_s(operator='')
      "(#{@subqueries.map(&:to_s).join(" #{operator} ")})"
    end
  end

  class AndStream < CombiningStream
    def combination(streams)
      ProcEnumerator.new do
        streams.each(&:rewind)
        values = streams.map(&:next_or_nil)
        lambda do
          if values.any? { |v| v.nil? }
            :stop_iteration
          else
            until values.all? { |v| v == values.first } || values.any?(&:nil?)
              index = values.index(values.min)
              values[index] = streams[index].next_or_nil
            end
            pivot = values.first
            until values[0].nil? || values[0] > pivot
              values[0] = streams[0].next_or_nil
            end
            pivot
          end
        end
      end
    end

    def to_s
      super('&')
    end
  end

  class OrStream < CombiningStream
    def combination(streams)
      ProcEnumerator.new do
        streams.each(&:rewind)
        values = streams.map(&:next_or_nil)
        lambda do
          if values.first.nil? && values.all?(&:nil?)
            :stop_iteration
          else
            smallest = values.compact.min
            streams.size.times do |i|
              until values[i].nil? || values[i] > smallest
                values[i] = streams[i].next_or_nil
              end
            end
            smallest
          end
        end
      end
    end

    def to_s
      super('|')
    end
  end

  class PlusStream < CombiningStream
    def combination(streams)
      ProcEnumerator.new do
        streams.each(&:rewind)
        values = streams.map(&:next_or_nil)
        lambda do
          if values.all?(&:nil?)
            :stop_iteration
          else
            smallest = values.compact.min
            index = values.index(smallest)
            values[index] = streams[index].next_or_nil
            smallest
          end
        end
      end
    end

    def to_s
      super('+')
    end
  end

  class MinusStream < CombiningStream
    def combination(streams)
      ProcEnumerator.new do
        streams.each(&:rewind)
        values = streams.map(&:next_or_nil)
        lambda do
          if values.first.nil? && values.all?(&:nil?)
            :stop_iteration
          else
            smallest = nil
            until smallest != nil || (values.first.nil? && values.all?(&:nil?))
              compact_values = values.compact
              smallest = compact_values.min
              if compact_values.count(smallest) == 1
                streams.size.times do |i|
                  until values[i].nil? || values[i] > smallest
                    values[i] = streams[i].next_or_nil
                  end
                end
              else
                values.replace(streams.map(&:next_or_nil))
                smallest = nil
              end
            end
            smallest || :stop_iteration
          end
        end
      end
    end

    def to_s
      super('-')
    end
  end
end