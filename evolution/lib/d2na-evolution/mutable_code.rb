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
    
    # Code, which be cloned to this one.
    attr_reader :parent
    
    # Create D²NA code. Block will be eval on new instance.
    def initialize(&block)
      @exists_conditions = Set[]
      @unused_conditions = []
      @conditions_permutations = [Set[]]
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
      @modified_rules = Set[]
      self.instance_eval(&block)
      @modified_rules.each do |rule|
        rule.compile
      end
      self
    end
    
    # Return Ruby representation of Code to save as file.
    def to_ruby
      'input  :' + (@input_signals - [:Init]).join(', :') + "\n" +
      'output :' + @output_signals.join(', :') + 
      @rules.inject('') do |all, rule|
        if 0 == rule.commands.length
          all
        else
          all + "\n\n" +
          'on :' + rule.conditions.join(', :') + " do\n" +
            rule.commands.inject('') { |all, i| all + "  #{i[0]} :#{i[1]}\n" } +
          'end'
        end
      end
    end
    
    # Delete rule from code and caches.
    def delete_rule(rule)
      set = rule.conditions.to_set
      @unused_conditions << set
      @exists_conditions.delete(set)
      @rules.delete(rule)
      rule.conditions.each do |condition|
        @conditions_cache[condition].delete(rule)
      end
      @length -= rule.commands.length
    end
    
    # Delete state, all it’s commands and rules with it in conditions.
    def remove_state(state)
      @conditions_cache[state].each do |rule|
        delete_rule(rule)
      end
      @conditions_cache.delete(state)
      @conditions_permutations.delete_if { |i| i.include? state }
      @unused_conditions.delete_if { |i| i.include? state }
      @states.delete(state)
      modify do
        @rules.each_with_index do |rule, rule_number|
          rule.commands.each_with_index do |command, command_number|
            if state == command[1]
              remove_command(command_number, rule_number)
              break
            end
          end
        end
      end
    end
    
    # Count of all conditions wich can be with this states and input signals.
    def conditions_count
      @rules.length + unused_conditions.length
    end
    
    # Clone object with all instance variables without rules.
    def clone
      another = super
      (instance_variables - ['@rules']).each do |name|
        value = instance_variable_get(name)
        if value.kind_of? Enumerable
          another.instance_variable_set(name, value.dup)
        end
      end
      another.instance_variable_set('@rules', @rules.clone)
      another.instance_variable_set('@parent', self)
      another
    end
    
    protected
    
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
        rule = @rules[rule_number].dup
        @rules[rule_number] = rule
      else
        rule = on(*@unused_conditions[rule_number - @rules.length].to_a)
      end
      rule.commands << [command, param]
      @modified_rules << rule
      @length += 1
    end
    
    # Delete command in special +position+ of all code if +rule+ is +nil+ or
    # in +position+ in rule with special number.
    #
    # Call this method in +modify+ block.
    def remove_command(position, rule_number = nil)
      if rule_number
        rule = @rules[rule_number]
        if 1 == rule.commands.length
          delete_rule(rule)
          @modified_rules.delete(rule)
        else
          rule = rule.dup
          @rules[rule_number] = rule
          rule.commands.delete_at(position)
          @modified_rules << rule
        end
        @length -= 1
        rule
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
