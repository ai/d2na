=begin
Return Ruby representation of D²NA code.

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
  module CodeRubinerMixin
    # Return Ruby representation of Code to save as file.
    def to_ruby
      'input  :' + (@input_signals - [:Init]).join(', :') + "\n" +
      'output :' + @output_signals.join(', :') + 
      @rules.inject('') { |all, i| all + "\n\n" + i.to_ruby }
    end
  end
  
  module RuleRubinerMixin
    # Return Ruby representation of Rule to save as file.
    def to_ruby
      'on :' + @conditions.join(', :') + " do\n" +
        @commands.inject('') { |all, i| all + "  #{i[0]} :#{i[1]}\n" } +
      'end'
    end
  end
  
  class Code
    include CodeRubinerMixin
  end
  class Rule
    include RuleRubinerMixin
  end
end
