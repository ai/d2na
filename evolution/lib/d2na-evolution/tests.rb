=begin
Group of tests for D²NA code.

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
  # Group of tests for code.
  class Tests
    # Array of tests.
    attr_reader :tests
    
    # Current test result.
    attr_reader :result
    
    # Current code to test.
    attr_reader :code
    
    # Constructor.
    def initialize
      @tests = []
    end
    
    # Add new test as block with +description+ and +priority+. It should be
    # eval on this instance.
    def add(description = nil, priority = 1, &block)
      @tests << [block, description, priority] if block_given?
    end
  end
end
