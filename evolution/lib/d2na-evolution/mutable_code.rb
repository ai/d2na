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

module D2NA
  # Extend D²NA Code to evolution: modify, mutate and print as Ruby core.
  class MutableCode < Code
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
      @modified_rules = []
      self.instance_eval(&block)
      @modified_rules.uniq.each do |rule|
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
    
    protected
    
    # Insert +command+ (<tt>:send</tt>, <tt>:up</tt> or <tt>:down</tt>) in this
    # +rule+ with +param+ (signal name to +send+ command or state name of
    # +up+/+down+ command).
    #
    # Call this method in +modify+ block.
    def add_command(rule, command, param)
      output param if :send == command
      @rules[rule].commands << [command, param]
      @modified_rules << @rules[rule]
      @length += 1
    end
    
    # Delete command in special +position+ of all code (start from zero).
    #
    # Call this method in +modify+ block.
    def remove_command(position)
      before = 0
      @rules.each do |rule|
        if before + rule.commands.length > position
          rule.commands.delete_at(position - before)
          @modified_rules << rule
          break
        else
          before += rule.commands.length
        end
      end
      @length -= 1
    end
  end
end
