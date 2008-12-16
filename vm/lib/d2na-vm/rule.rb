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
    
    # Create D²NA rule with special conditions.
    def initialize(conditions)
      @conditions = conditions
    end
  end
end
