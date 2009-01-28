=begin
Record output signals from D²NA code.

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
  # Array to record output signals from Code.
  #
  #   out = D2NA::Recorder.new(code)
  #   code << :A << :A
  #   out #=> [:B, :B]
  class Recorder < ::Array
    # Code to record.
    attr_reader :code
    
    # Start recording signals from +code+.
    def initialize(code)
      super(0)
      @signals = []
      @code = code
      @code.listen &method(:dispatch)
    end
    
    # Record new output signal. It will called by code.
    def dispatch(code, signal)
      self << signal
    end
  end
end
