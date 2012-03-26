# encoding: utf-8

module StreamLogic
	module EnumeratorHelpers
		def safe_next(enum)
			enum.next
		rescue StopIteration
			nil
		end
	end

	module CombinationOperators
		def &(query)
			AndStream.new(self, query)
		end

		def |(query)
			OrStream.new(self, query)
		end
	end

	class Stream
		include Enumerable
		include CombinationOperators

		def initialize(enumerable=nil, &block)
			@enumerable = enumerable
			@constructor = block
		end

		def each(&block)
			enumerable = @enumerable || @constructor.call
			return enumerable.each unless block_given?
			enumerable.each(&block)
		end
	end

	class CombiningStream
		include Enumerable
		include EnumeratorHelpers
		include CombinationOperators

		def initialize(*subqueries)
			@subqueries = subqueries
		end

		def each(&block)
			enum = combination(@subqueries)
			return enum unless block_given?
			enum.each(&block)
		end

		def combination
			raise NotImplementedError, %(#combination not implemented!)
		end
	end

	class AndStream < CombiningStream
		def combination(queries)
			Enumerator.new do |yielder|
				enums = queries.map(&:each)
				values = enums.map { |e| safe_next(e) }
				until values.any? { |v| v.nil? }
					until values.all? { |v| v == values.first } || values.any? { |v| v.nil? }
						index = values.index(values.min)
						values[index] = safe_next(enums[index])
					end
					yielder << values.first unless values.any? { |v| v.nil? }
					values = enums.map { |e| safe_next(e) }
				end
			end
		end
	end

	class OrStream < CombiningStream
		def combination(queries)
			Enumerator.new do |yielder|
				enums = queries.map(&:each)
				values = enums.map { |e| safe_next(e) }
				loop do
					break if values.all? { |v| v.nil? }
					smallest = values.compact.min
					yielder << smallest
					enums.each_with_index do |enum, i|
						if values[i] && values[i] <= smallest
							until values[i].nil? || values[i] > smallest
								values[i] = safe_next(enum)
							end
						end
					end
				end
			end
		end
	end
end