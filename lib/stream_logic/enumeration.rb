# encoding: utf-8

module StreamLogic
  module ExternalEnumeration
    include Enumerable

    def each
      rewind
      return self unless block_given?
      while (v = next_element) != :stop_iteration
        yield v
      end
    end

    def next
      v = next_element
      raise StopIteration if v == :stop_iteration
      v
    end

    def next_or_nil
      v = next_element
      return nil if v == :stop_iteration
      v
    end
  end

  class EnumeratorEnumerator
    include ExternalEnumeration

    def initialize(enumerator)
      @enumerator = enumerator
    end

    def next_element
      @enumerator.next
    rescue StopIteration
      :stop_iteration
    end

    def rewind
      @enumerator.rewind
    end
  end

  class ArrayEnumerator
    include ExternalEnumeration

    def initialize(array)
      @array = array
      @index = 0
    end

    def next_element
      return :stop_iteration if @index >= @array.size
      v = @array[@index]
      @index += 1
      v
    end

    def rewind
      @index = 0
    end
  end

  class IoEnumerator
    include ExternalEnumeration

    def initialize(io)
      @io = io
    end

    def next_element
      v = @io.gets
      return :stop_iteration unless v
      v
    end

    def rewind
      @io.seek(0, IO::SEEK_SET)
    end
  end

  class ProcEnumerator
    include ExternalEnumeration

    def initialize(constructor=nil, &block)
      @constructor = constructor || block
    end

    def next_element
      @generator ||= @constructor.call
      @generator.call
    end

    def rewind
      @generator = nil
    end
  end
end