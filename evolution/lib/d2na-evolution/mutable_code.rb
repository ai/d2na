# encoding: utf-8
=begin
Extend D²NA Code to evolution: modify, mutate and print as Ruby core.

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

require 'set'

module D2NA
  # Extend D²NA Code to evolution: modify, mutate and print as Ruby core.
  class MutableCode < Code
    # Conditions without rules.
    attr_reader :unused_conditions
    
    # Default mutation parameters. See +mutate+ for key description.
    attr_reader :mutation_params
    
    # All available commands for this code
    attr_reader :commands
    
    # Create D²NA code. Block will be eval on new instance.
    def initialize(&block)
      @exists_conditions = Set[]
      @unused_conditions = []
      @conditions_permutations = [Set[]]
      @commands = []
      @modify_depth = 0
      @generated_states = 0
      
      @mutation_params = {
        min_actions: 1,       max_actions: 2,
        min_state_actions: 3, max_state_actions: 9,
        add: 0.5,             remove: 0.1,
        add_state: 0.05,      remove_state: 0.01
      }
      super(&block)
    end
    
    # Add new input +signals+. Input signal name must start from upper case
    # letter (for example, <tt>:Input</tt>).
    def input(*signals)
      super(*signals).each do |signal|
        if :Init == signal
          add_unused_conditions(Set[:Init])
        else
          @conditions_permutations.each do |states|
            add_unused_conditions(states + [signal])
          end
        end
      end
    end
    
    # Add new output +signals+. Return new signals.
    def output(*signals)
      super(*signals).each do |signal|
        @commands << [:send, signal]
      end
    end
    
    # Define +states+. State name must start from lower case latter
    # (for example, <tt>:state</tt>).
    def add_states(*states)
      super(*states).each do |state|
        @conditions_permutations += @conditions_permutations.map do |i|
          conditions = i + [state]
          add_unused_conditions(conditions)
          (@input_signals - [:Init]).each do |signal|
            add_unused_conditions(conditions + [signal])
          end
          conditions
        end
        @commands << [:up, state] << [:down, state]
      end
    end
    
    # Add new Rule with special +conditions+ of input signals and non-zero
    # states which is necessary to start commands. Input signal name must
    # start from upper case letter. Block will be eval on rule, so you can set
    # commands by +up+, +down+ and +send+ Rule methods.
    def on(*conditions, &block)
      set = conditions.to_set
      @exists_conditions << set
      @unused_conditions.delete(set)
      super(*conditions, &block)
    end
    
    # Use +add_command+ and +remove_command+ in block of this method to modify
    # code. Block will be eval on Code instance. For example:
    #
    #   code = D2NA::Code.new do
    #     on :Init do
    #       up :waiting
    #     end
    #     on :Input do
    #       send :Output
    #       down :waiting
    #     end
    #   end
    #   
    #   code.modify do
    #     add_command(0, :send, :Started)
    #     remove_command(3)
    #   end
    #
    # Result:
    # 
    #   on :Init do
    #     up :waiting
    #     send :Started
    #   end
    #   on :Input do
    #     send :Output
    #   end
    def modify(&block)
      @modify_depth += 1
      
      if 1 == @modify_depth
        @modified_rules = Set[]
        self.instance_eval(&block)
        
        @modified_rules.each do |rule|
          rule.compile
        end
      else
        self.instance_eval(&block)
      end
      
      @modify_depth -= 1
      self
    end
    
    # Add random changes to code. Parameters (optionally):
    # * +min_actions+/+max_actions+: min and max actions on one mutation;
    # * +min_state_actions+/+max_state_actions+: min and max actions after
    #   adding new state;
    # * +add+/+remove+: probability of adding or removing command;
    # * +add_state+/+remove_state+: probability of adding or removing state.
    def mutate!(params = {})
      p = @mutation_params.merge(params)
      sum = p[:add] + p[:remove] + p[:add_state] + p[:remove_state]
      state_actions = (p[:max_state_actions] - p[:min_state_actions]) / 3
      min_state_actions = p[:min_state_actions] /= 3
      
      count = rand(p[:max_actions] - p[:min_actions]).floor + p[:min_actions]
      modify do
        count.times do
          choice = sum * rand
          if choice < p[:add]
            # Add command
            add_command rand(conditions_count),
                        *@commands[rand(@commands.length)]
            
          elsif choice < p[:add] + p[:remove]
            # Remove command
            remove_command(rand(length))
            
          elsif choice < sum - p[:remove_state]
            # Add state
            state = new_state_name
            before_conditions = conditions_count
            before_commands = @commands.length
            add_states(state)
            conditions_diff = conditions_count - before_conditions
            
            state_count = rand(state_actions).floor + min_state_actions
            state_count.times do
              add_command rand(before_conditions), :up, state
              add_command rand(before_conditions), :down, state
              add_command before_conditions + rand(conditions_diff),
                          *@commands[rand(@commands.length)]
            end
            
          elsif not @states.empty?
            # Remove state
            remove_state @states.keys[rand(@states.length)]
          end
        end
      end
    end
    
    # Return Ruby representation of Code to save as file.
    def to_ruby
      'input  :' + (@input_signals - [:Init]).join(', :') + "\n" +
      'output :' + @output_signals.join(', :') + 
      @rules.inject('') do |all, rule|
        all + "\n\n" +
        'on :' + rule.conditions.join(', :') + " do\n" +
          rule.commands.inject('') { |a, i| a + "  " + i.join(' :') + "\n" } +
        'end'
      end
    end
    
    # Delete rule from code and caches.
    def delete_rule(rule)
      set = rule.conditions.to_set
      @unused_conditions << set
      @exists_conditions.delete(set)
      @rules.delete(rule)
      @required.delete(rule)
      rule.conditions.each do |condition|
        @conditions_cache[condition].delete(rule)
      end
      @length -= rule.commands.length
    end
    
    # Delete state, all it’s commands and rules with it in conditions.
    def remove_state(state)
      @conditions_cache[state].clone.each do |rule|
        delete_rule(rule)
      end
      modify do
        rule_number = 0
        while @rules.length - 1 >= rule_number
          rule = @rules[rule_number]
          command_number = 0
          while rule.commands.length - 1 >= command_number
            if state == rule.commands[command_number][1]
              rule = remove_command(command_number, rule_number)
              break unless rule
            else
              command_number += 1
            end
          end
          rule_number += 1 if rule
        end
      end
      @conditions_cache.delete(state)
      @conditions_permutations.delete_if { |i| i.include? state }
      @unused_conditions.delete_if { |i| i.include? state }
      @commands.delete([:up, state])
      @commands.delete([:down, state])
      @states.delete(state)
    end
    
    # Count of all conditions wich can be with this states and input signals.
    def conditions_count
      @rules.length + unused_conditions.length
    end
    
    # Clone object with all instance variables extend rules.
    def clone
      clone = super
      instance_variables.each do |name|
        clone.instance_variable_set(name,
            deep_clone(clone.instance_variable_get(name)))
      end
      clone
    end
    
    protected
    
    # Clone +obj+ and all object inside it extend Rule and Code instances.
    def deep_clone(obj)
      case obj
        when Fixnum, Bignum, Float, NilClass, FalseClass, TrueClass, Symbol,
             Rule, Code
          return obj
        when Hash
          clone = obj.clone
          obj.each { |key, value| clone[deep_clone(key)] = deep_clone(value) }
        when Array
          clone = obj.clone.map { |i| deep_clone(i) }
        else
          clone = obj.clone
          clone.instance_variables.each do |name|
            clone.instance_variable_set(name,
                deep_clone(clone.instance_variable_get(name)))
          end
      end
      clone
    end
    
    # Get next new unused state name.
    def new_state_name
      @generated_states += 1
      num = @generated_states - 1
      name = ''
      begin
        name << ('a'.ord + num % 26).chr
        num /= 26
      end while 0 < num
      name.to_sym
    end
    
    # Add conditions as unused if it isn’t used in rules.
    def add_unused_conditions(conditions)
      unless @exists_conditions.include? conditions
        @unused_conditions << conditions
      end
    end
    
    # Insert +command+ (<tt>:send</tt>, <tt>:up</tt> or <tt>:down</tt>) with
    # +param+ (signal name to +send+ command or state name of +up+/+down+
    # command) in rule with special +rule_number+.
    #
    # You can use number more that rules exists – rule will be created from
    # +unused_conditions+. Rule number must be less, that +conditions_count+.
    #
    # Call this method in +modify+ block.
    def add_command(rule_number, command, param)
      output param if :send == command
      if @rules.length > rule_number
        old = @rules[rule_number]
        @modified_rules.delete(old)
        @rules[rule_number] = rule = clone_rule(old)
      else
        condition = @unused_conditions[rule_number - @rules.length]
        return unless condition
        rule = on(*condition.to_a)
      end
      rule.commands << [command, param]
      @modified_rules << rule
      @length += 1
    end
    
    # Clone rule and change all necessary caches. Used in copy on write.
    def clone_rule(rule)
      clone = rule.dup
      clone.commands = deep_clone(clone.commands)
      @required[clone] = @required.delete(rule)
      rule.conditions.each do |condition|
        @conditions_cache[condition].delete(rule)
        @conditions_cache[condition] << clone
      end
      clone
    end
    
    # Delete command in special +position+ of all code if +rule+ is +nil+ or
    # in +position+ in rule with special number.
    #
    # Call this method in +modify+ block.
    def remove_command(position, rule_number = nil)
      if rule_number
        rule = @rules[rule_number]
        @modified_rules.delete(rule)
        if 1 == rule.commands.length
          delete_rule(rule)
          nil
        else
          rule = clone_rule(rule)
          @rules[rule_number] = rule
          rule.commands.delete_at(position)
          @modified_rules << rule
          @length -= 1
          rule
        end
      else
        before = 0
        @rules.each_with_index do |rule, i|
          if before + rule.commands.length > position
            return remove_command(position - before, i)
          end
          before += rule.commands.length
        end
      end
    end
  end
end
