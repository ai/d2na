# encoding: utf-8
=begin
Timeout error on stagnation excess.

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
  # Raised by Evolution, when it can generate necessary code (stagnation is more
  # that maximum limit by +stagnation_limit+).
  class Timeout < RuntimeError
    def initialize(stagnation_limit)
      super("Evolution can't generate necessary code. " +
            "There is no new result after #{stagnation_limit} steps.")
    end
  end
end
