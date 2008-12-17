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
    
    # Create D²NA code. Block will be eval on new instance.
    def initialize(&block)
      @rules = []
      instance_eval(&block) if block_given?
    end
    
    # Add new Rule with special +conditions+ of input signals and non-zero
    # states which is neccessary to start this code. Input signals name must
    # start from upper case letter (for example, <tt>:Input</tt>). Block will be
    # eval on rule, so you can set commands by +up+, +down+ and +send+ Rule
    # methods.
    def on(*conditions, &block)
      @rules << Rule.new(conditions, &block)
    end
  end
end
