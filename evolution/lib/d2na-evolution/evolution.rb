# encoding: utf-8
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
    
    # Population from previous step.
    attr_reader :old_population
    
    # Current population.
    attr_reader :population
    
    # Best result of previous step.
    attr_reader :last_best_result
    
    # Count of steps without new best result.
    attr_reader :stagnation
    
    # Create new evolution. You can configure it in block, which will be eval
    # on new instance.
    def initialize(&block)
      @tests = Tests.new
      @first_population = 10
      @worker_count = 2
      @protocode = MutableCode.new
      @stagnation = 0
      @end_checker = lambda { success }
      instance_eval(&block) if block_given?
      
      @workers = []
      @worker_count.times do
        @workers << Worker.new(self)
      end
      
      @population = D2NA::Population.new(@first_population,
                                         @protocode, @tests.run(@protocode))
    end
    
    # Set first version of code, which will be used on first step. Usual first
    # version of code specify only input and output signals (because mutation
    # didn’t change I/O interface), but you can also specify default mutatation
    # parameters or default rules.
    #
    # Note, that you can use it only in constructor block.
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
          @protocode.instance_eval(&block)
        else
          return @protocode
        end
      else
        unless protocode.kind_of? MutableCode
          [:<<, :listen, :mutate!].each do |method|
            unless protocode.methods.include? method
              raise ArgumentError, "User protocode didn't has #{method} method"
            end
          end
        end
        @protocode = protocode
      end
    end
    
    # Set workers count. If you didn’t set argument it return current count.
    # You can use it only in constructor block.
    #
    # Workers do parallel tasts in separated threads for performance on
    # multicore processors. You should set as many workers, as you have CPU
    # cores.
    #
    # Usage (for example on Intel Core i7):
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
    # value. You can use it only in constructor block.
    # 
    # First population will be contain only clone of protocode without any
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
    # Note, that you can use it only in constructor block.
    #
    # First argument is test description, like in RSpec. In second you can set
    # <tt>:priority</tt> with value. In block you can use:
    # * <tt>send :Signal</tt> to send signal to testing code;
    # * <tt>out_should Signal: count</tt> to match all sent output signals
    #   counts;
    # * <tt>out_should_has Signal: count</tt> to match only selected output
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
    #   selection "example test", priority: 2 do
    #     out_should_be_empty
    #     send :A, :A, :B
    #     out_should_has A: 2, B: 1
    #     out_should_has B: 1
    #     clear_out
    #     send :A
    #     out_should_hasnt :B, priority: 4
    #     should out.length == 1
    #     min code.length, priority: 0.5
    #   end
    def selection(description = nil, options = {}, &block)
      raise ArgumentError, 'Test must have block with code' unless block_given?
      if Hash == description.class and options.empty?
        options = description
        description = nil
      end
      @tests.add(description, options[:priority] || 1, &block)
    end
    
    # Set conditions to end evolution iterations. You should use:
    # * +success+ to check is a best result in current population match all
    #   boolean tests;
    # * <tt>stagnation == _count_</tt> to check evolution stagnation – count of
    #   iteration without new result.
    # 
    # Check success if there is a specific necessary result. For example, if
    # you generate summator and code must send exactly 5 +C+ signals, if it
    # receive 3 +A+ and 2 +B+.
    # 
    #   end_if { success }
    #
    # Check stagnation if there isn’t specific result – test must have most
    # minimum or maximum result of the possible. For example, if code size
    # must be minimum. Big stagnation length require more time to generate.
    # Small length can miss better result.
    # 
    #   end_if { stagnation == 100 }
    #
    # It is useful to use both checkers:
    # 
    #   end_if { success and stagnation == 100 }
    #
    # If you has optional boolean test, but didn’t know is it possible, use
    # +or+ group:
    # 
    #   end_if { success or stagnation == 100 }
    def end_if(&checker)
      @end_checker = checker if block_given?
    end
    
    # Do next evolution iteration: clone, mutate and select population. Use
    # +end_if+ to set end conditions and +end?+ to check it.
    # 
    #   while evolution.end?
    #     evolution.step!
    #   end
    def step!
      @old_population = @population
      @last_best_result = @old_population.best_result
      @population = Population.new
      
      @workers.each { |i| i.run }
      @workers.each { |i| i.thread.join }
      
      if @last_best_result == @population.best_result
        @stagnation += 1
      else
        @stagnation = 0
      end
    end
    
    # Return true on end conditions, which was set by +end_if+. Use in the
    # loop with +step!+ call:
    # 
    #   while evolution.end?
    #     evolution.step!
    #   end
    def end?
      @end_checker.call
    end
    
    # Alias for <tt>population.best_result.success?</tt> to use in +end_if+ as
    # condition.
    def success
      @population.best_result.success?
    end
  end
end
