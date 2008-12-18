=begin
D²NA code.

Copyright (C) 2008 Andrey “A.I.” Sitnik <andrey@sitnik.ru>

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
  # D²NA code with several Rule blocks. Receive and send signals and store state
  # values.
  class Code
    # Array of Rule with conditions and commands.
    attr_reader :rules
    
    # Input signals, which this Code can receive. To add one use +input+ method.
    attr_reader :input_signals
    
    # Output signals, which this Code may send. To add one use +output+ method.
    attr_reader :output_signals
    
    # Hash of states with name (Symbol) as key and it value (Number) as value.
    attr_reader :states
    
    # Hash with condition as key and dependency rule as value.
    attr_reader :conditions_cache
    
    # Create D²NA code. Block will be eval on new instance.
    def initialize(&block)
      @rules = []
      @input_signals = []
      @output_signals = []
      @states = {}
      @diff = {}
      @conditions_cache = {}
      @listeners_all = []
      @listeners_signals = {}
      instance_eval(&block) if block_given?
    end
    
    # Add new input +signals+. Input signals name must start from upper case
    # letter (for example, <tt>:Input</tt>).
    def input(*signals)
      signals.each do |signal|
        next if @input_signals.include? signal
        check_signal_name(signal)
        @input_signals << signal
        @conditions_cache[signal] = []
      end
    end
    
    # Add new output +signals+.
    def output(*signals)
      signals.each do |signal|
        @output_signals << signal unless @output_signals.include? signal
      end
    end
    
    # Add new Rule with special +conditions+ of input signals and non-zero
    # states which is neccessary to start this code. Input signals name must
    # start from upper case letter. Block will be eval on rule, so you can set
    # commands by +up+, +down+ and +send+ Rule methods.
    def on(*conditions, &block)
      rule = Rule.new(conditions, self, &block)
      @rules << rule
      rule.conditions.each { |c| @conditions_cache[c] << rule }
      rule
    end
    
    # Define +states+. State name must start from lower case latter
    # (for example, <tt>:state</tt>).
    def state(*states)
      states.each do |name|
        if name.to_s =~ /^[A-Z]/
          raise ArgumentError, 'State name must not be capitalized'
        end
        unless @states.has_key? name
          @states[name] = 0
          @diff[name] = 0
          @conditions_cache[name] = []
        end
      end
    end
    
    # Set block to listen some +signals+ (names or nil for all). First argument
    # of block will be this Code, second - signal name.
    def listen(*signals, &block)
      if signals.empty?
        @listeners_all << block
      else
        signals.each do |signal|
          if @listeners_signals.has_key? signal
            @listeners_signals[signal] << block
          else
            @listeners_signals[signal] = [block]
          end
        end
      end
    end

    # Send input +signal+ into Code. Signals name must start from upper case
    # letter.
    def send_in(signal)
      return unless @input_signals.include? signal
      
      check_signal_name(signal)
      @conditions_cache[signal].each do |rule|
        rule.call if 1 == rule.required
      end
      
      rule_to_run = {}
      while not @diff.empty? or not rule_to_run.empty?
        @diff.each_pair do |state, diff|
          @conditions_cache[state].each do |rule|
            rule.required -= diff
            rule_to_run[rule] = (0 == rule.required)
          end
        end
        @diff = {}
        rule_to_run.delete_if { |rule, run| not run }
        rule_to_run.each_key do |rule|
          rule.call
        end
      end
    end
    alias << send_in
    
    # Send output +signal+ from Code to listeners.
    def send_out(signal)
      @listeners_all.each { |i| i.call(self, signal) }
      if listeners = @listeners_signals[signal]
        listeners.each { |i| i.call(self, signal) }
      end
    end
    
    # Increment +state+ value.
    def state_up(state)
      @states[state] += 1
      if 1 == @states[state]
        if -1 == @diff[state]
          @diff.delete state
        else
          @diff[state] = 1
        end
      end
    end
    
    # Decrement +state+ value.
    def state_down(state)
      @states[state] -= 1
      if 0 == @states[state]
        if 1 == @diff[state]
          @diff.delete state
        else
          @diff[state] = -1
        end
      end
    end
    
    protected
    
    # Check, that +signal+ name start from upper case letter.
    def check_signal_name(signal)
      unless signal.to_s =~ /^[A-Z]/
        raise ArgumentError, 'Signal name must be capitalized'
      end
    end
  end
end
