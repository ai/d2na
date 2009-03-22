# encoding: utf-8
=begin
Population of D²NA codes.

Copyright (C) 2009 Andrey “A.I.” Sitnik <andrey@sitnik.ru>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

module D2NA
  # Collection of codes grouped by test results.
  class Population
    # Test results for codes in population.
    attr_accessor :results
    
    # Codes grouped by results.
    attr_accessor :layers
    
    # Create new population and fill to +size+ it by +protocode+ with it test
    # +result+.
    def initialize(size = 0, protocode = nil, result = nil)
      @mutex = Mutex.new
      if size.zero?
        @results = []
        @layers = []
      else
        @results = [result]
        @layers = [Array.new(size, protocode)]
      end
    end
    
    # Insert new +code+ with it test +result+ in population. It is thread safe.
    def push(code, result)
      @mutex.synchronize do
        if @layers.empty?
          @results << result
          @layers << [code]
        else
          @layers[result_index(result)] << code
        end
      end
    end
    
    # Remove and return last code. It is thread safe.
    def pop
      @mutex.synchronize do
        return nil if @layers.empty?
        if @layers.last.empty?
          @layers.pop
          @results.pop
          return nil if @layers.empty?
        end
        @layers.last.pop
      end
    end
    
    # Best test result from population.
    def best_result
      @results.first
    end
    
    # Delete bad results. Maximum length of best layer with be +firts+. Every
    # next layer will be less than +decrease+ times.
    def trim(first, decrease)
      layers_count = Math.log(first, decrease).floor + 1
      @layers = @layers.take(layers_count)
      @results = @results.take(layers_count)
      
      next_length = first
      @layers.map! do |layer|
        length = next_length
        next_length = length / decrease
        layer.take(length)
      end
    end
    
    protected
    
    # Find index for +result+ by binary search or insert new result.
    def result_index(result)
      lower = 0
      upper = @results.length
      mid = 0
      answer = 0
      while lower + 1 != upper
        mid = ((lower + upper) / 2).to_i
        case @results[mid] <=> result
        when  0
          return mid
        when  1
          lower = mid
          answer = upper
        when -1
          upper = mid
          answer = lower
        end
      end
      
      #TODO fix binary search to remove this hack
      answer -= 1 if @results.length == answer
      
      case @results[answer] <=> result
      when 0
        return answer
      when 1
        answer += 1
      end
      @results.insert(answer, result)
      @layers.insert(answer, [])
      answer
    end
  end
end
