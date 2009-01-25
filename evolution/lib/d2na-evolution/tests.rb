=begin
Group of tests for D²NA code.

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
  # Group of tests for code.
  class Tests
    # Array of tests.
    attr_reader :tests
    
    # Current test result.
    attr_reader :result
    
    # Current code to test.
    attr_reader :code
    
    # Constructor.
    def initialize
      @tests = []
    end
    
    # Add new test as block with +description+ and +priority+. It should be
    # eval on this instance.
    def add(description = nil, priority = 1, &block)
      @tests << [block, description, priority] if block_given?
    end
    
    # Run test for +code+ and return it result.
    def run(code)
      @code = code
      @code.listen &method(:record_signal)
      @output_signals = Hash.new(0)
      
      @result = TestResult.new
      @tests.each do |test, description, priority|
        @current_priority = priority
        instance_eval &test
        @code.reset!
      end
      @result
    end
    
    # Record output signal from +code+.
    def record_signal(code, signal)
      @output_signals[signal] += 1
    end
  
    protected
    
    # Match all output signals count. In first argument put signal
    # name as key and count as value. You can also use key <tt>:priority</tt>.
    #
    #   out_should :A => 1, :B => 5, :priority => 2
    def out_should(signals)
      priority = signals[:priority] || @current_priority
      signals.delete :priority
      
      bad = 0
      @code.output_signals.each do |name|
        exists = @output_signals[name]
        if signals.has_key? name
          count = signals[name]
          @result.match(count == exists, priority)
          @result.min((exists - count).abs, priority)
        else
          bad += exists
        end
      end
      
      @result.match(0 == bad, priority)
      @result.min(bad, priority)
    end
    
    # Match some output signals count. It is like +out_should+ but didn’t match
    # signals, that you didn’t set in signals.
    def out_should_has(signals)
      priority = signals[:priority] || @current_priority
      signals.delete :priority
      
      signals.each_pair do |name, count|
        exists = @output_signals[name]
        @result.match(count == exists, priority)
        @result.min((exists - count).abs, priority)
      end
    end
    
    # Send signals to +code+.
    def send(*signals)
      signals.each { |i| code << i }
    end
    
    # Shortcut to <tt>result.match</tt> to add boolean test. +options+ may
    # include <tt>:priority</tt>.
    #
    #   should 1 == var
    #   should 2 == count, :priority => 2
    def should(test, options = {})
      @result.match(test, options[:priority] || @current_priority)
    end
    
    # Shortcut to <tt>result.min</tt> to add +value+ that should be min.
    # +options+ may include <tt>:priority</tt>.
    #
    #   min errors, :priority => 2
    def min(value, options = {})
      @result.min(value, options[:priority] || @current_priority)
    end
    
    # Shortcut to <tt>result.max</tt> to add +value+ that should be max.
    # +options+ may include <tt>:priority</tt>.
    #
    #   max count, :priority => 2
    def max(value, options = {})
      @result.max(value, options[:priority] || @current_priority)
    end
  end
end
