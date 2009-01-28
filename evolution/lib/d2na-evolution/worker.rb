=begin
Evolution worker to work with D²NA code.

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
  # Worker to do parallel tasks in evolution process.
  class Worker
    # Link to owner evolution.
    attr_reader :evolution
    
    # Own cloned copy of tests from Evolution.
    attr_reader :tests
    
    # Create new worker for some +evolution+. You must already create all tests
    # in Tests instance.
    def initialize(evolution)
      @evolution = evolution
      @tests = evolution.tests.dup
    end
  end
end
