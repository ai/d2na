=begin
Block of D²NA code.

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
  # Block of D²NA code. Contain commands (output signals and state changes), 
  # which will be executed on special condition (input signals and non-zero
  # states).
  class Rule
    # Array of names (Symbol) of input signals and non-zero states which is
    # neccessary to start this code. Input signals name must start from upper
    # case letter (for example, <tt>:Input</tt>).
    attr_reader :conditions
    
    # Array of block commands (<tt>[:type, :name]</tt>). Type can be
    # <tt>:up</tt>, <tt>:down</tt> (increment/decrement state) or <tt>:send</tt>
    # (send output signal). Name should be state or output signal name.
    attr_reader :commands
    
    # Code, which store state value and receive and send signals for this rule.
    attr_accessor :owner
    
    # Create D²NA rule for +owner+ Code with special +conditions+. In block you
    # can call +up+, +down+ and +send+ methods to add commands.
    def initialize(conditions, owner, &block)
      @conditions = conditions
      @owner = owner
      @commands = []
      instance_eval(&block) if block_given?
    end
    
    # Add command to increment +state+.
    def up(state)
      @commands << [:up, state]
    end
    
    # Add command to decrement +state+.
    def down(state)
      @commands << [:down, state]
    end
    
    # Add command to send output +signal+.
    def send(signal)
      @commands << [:send, signal]
    end
  end
end
