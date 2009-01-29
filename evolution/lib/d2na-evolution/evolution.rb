=begin
Control evolution for D²NA code.

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
  # Evolution controller.
  class Evolution
    # Code tests, which will direct evolution.
    attr_reader :tests
    
    # First version of code to start evolution.
    attr_reader :protocode
    
    # Working count.
    attr_reader :worker_count
    
    # Array of workers.
    attr_reader :workers
    
    # First population size.
    attr_reader :first_population
    
    # Create new evolution. You can configure it in block, which will be eval
    # on new instance.
    def initialize(&block)
      @tests = Tests.new
      @first_population = 10
      @worker_count = 2
      instance_eval(&block) if block_given?
      
      @workers = []
      @worker_count.times do
        @workers << Worker.new(self)
      end
    end
    
    # Set first version of code, which will be used on first step. Usual first
    # version of code specify only input and output signals (because mutation
    # didn’t change I/O interface), but you can also specify default mutatation
    # parameters or default rules.
    #
    # If you didn’t set object in first argument, you must set block, that will
    # be eval on new MutableCode instance. If you call it without arguments and
    # block, it return current protocode.
    #
    # First version must be instance of MutableCode, not simple Code. But you
    # can use any another object, that has methods:
    # * <tt><< signal</tt> to send input signal;
    # * <tt>listen(*signals, &block)</tt> to add output signals listeners;
    # * <tt>mutate!</tt> to add random changes.
    #
    # Usage:
    # 
    #   protocode do
    #     input :A
    #     output :B
    #   end
    # 
    # Or with user code object:
    # 
    #   protocode MySuperDNA.new
    def protocode(protocode = nil, &block)
      if protocode.nil?
        if block_given?
          @protocode = MutableCode.new(&block)
        else
          return @protocode
        end
      else
        unless protocode.kind_of? MutableCode
          %w{<< listen mutate!}.each do |method|
            unless protocode.methods.include? method
              raise ArgumentError, "User protocode didn't has #{method} method"
            end
          end
        end
        @protocode = protocode
      end
    end
    
    # Set workers count. If you didn’t set argument it return current count.
    #
    # Workers do parallel tasts in separated threads for performance on
    # multicore processors. You should set as many workers, as you have CPU
    # cores.
    #
    # Usage (for example on On Intel Core i7):
    #
    #   worker_count 4
    def worker_count(count = nil)
      if count.nil?
        @worker_count
      else
        @worker_count = count
      end
    end
    
    # Set first population size. If you didn’t set argument it return current
    # value.
    # 
    # First popilation will be contain only clone of protocode without any
    # changes. This parameter influence only in first steps, so there is
    # no reason to change it in standart project.
    #
    #   first_population 10
    def first_population(count = nil)
      if count.nil?
        @first_population
      else
        @first_population = count
      end
    end
    
    # Add new test for code, which will direct evolution. This test didn’t say
    # only success or fail, it say that some code has result better than
    # another, even if they are success or fail together.
    #
    # First argument is test description, like in RSpec. In second you can set
    # <tt>:priority</tt> with value. In block you can use:
    # * <tt>send :Signal</tt> to send signal to testing code;
    # * <tt>out_should :Signal => count</tt> to match all sent output signals
    #   counts;
    # * <tt>out_should_has :Signal => count</tt> to match only selected output
    #   signals;
    # * <tt>out_should_hasnt :Signal</tt> to match that this output signals
    #   isn’t be sent.
    # * <tt>out_should_be_empty</tt> to match, that out is empty;
    # * <tt>clear_out</tt> to clear output signals queue for <tt>out_*</tt>
    #   matchers;
    # * <tt>should out.length == 5</tt> to match some boolean test;
    # * <tt>min value</tt> to select code, that has minimum value;
    # * <tt>max value</tt> to select code, that has maximum value.
    # In all matchers (<tt>out_*</tt>, +should+ and +min+/+max+) you can set
    # <tt>:priority</tt> with value. See Tests documentation for all available
    # methods and information. 
    #
    # Usage:
    # 
    #   selection "example test", :priority => 2 do
    #     out_should_be_empty
    #     send :A, :A, :B
    #     out_should_has :A => 2, :B => 1
    #     out_should_has :B => 1
    #     clear_out
    #     send :A
    #     out_should_hasnt :B, :priority => 4
    #     should out.length == 1
    #     min code.length, :priority => 0.5
    #   end
    def selection(description = nil, options = {}, &block)
      raise ArgumentError, 'Test must have block with code' unless block_given?
      if Hash == description.class and options.empty?
        options = description
        description = nil
      end
      @tests.add(description, options[:priority], &block)
    end
  end
end
