# encoding: utf-8
=begin
Test result for D²NA code.

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
  # Test result, which can be compare with another result.
  class TestResult
    include Comparable
    
    # Boolean tests.
    attr_reader :tests
    
    # Count of success boolean test, multiplied by priority.
    attr_reader :score
        
    # Values, that should be min.
    attr_reader :to_min
    
    # Sum of values, that should be min, multiplied by priority.
    attr_reader :sum_to_min
    
    # Values, that should be max.
    attr_reader :to_max
    
    # Sum of values, that should be max, multiplied by priority.
    attr_reader :sum_to_max
    
    # Constructor.
    def initialize
      @tests = []
      @to_min = []
      @to_max = []
      @success = true
      @score = 0
      @sum_to_min = 0
      @sum_to_max = 0
    end
    
    # Add new boolean +test+ with some +priority+.
    def match(test, priority = 1)
      @success &= test
      @score += priority if test
      @average_score = nil
      @tests << test
    end
    
    # Add new +value+, that should be min, with some +priority+.
    def min(value, priority = 1)
      @sum_to_min += priority * value
      @average_to_min = nil
      @to_min << value
    end
    
    # Add new +value+, that should be max, with some +priority+.
    def max(value, priority = 1)
      @sum_to_max += priority * value
      @average_to_max = nil
      @to_max << value
    end
    
    # Return true if all boolean test are success.
    def success?
      @success
    end
    
    # Average of count of success boolean test, multiplied by priority.
    def average_score
      @average_score ||= if @tests.empty?
        0
      else
        @score / @tests.length
      end
    end
    
    # Average sum of values, that should be min, multiplied by priority.
    def average_to_min
      @average_to_min ||= if @to_min.empty?
        0
      else
        @sum_to_min / @to_min.length
      end
    end
    
    # Average sum of values, that should be max, multiplied by priority.
    def average_to_max
      @average_to_max ||= if @to_max.empty?
        0
      else
        @sum_to_max / @to_max.length
      end
    end
    
    # Compare two tests results.
    def <=>(another)
      if average_score != another.average_score
        return average_score <=> another.average_score
      end
      
      diff = average_to_max - another.average_to_max
      diff -= average_to_min - another.average_to_min
      
      diff <=> 0
    end
  end
end
