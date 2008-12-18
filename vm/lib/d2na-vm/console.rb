=begin
Run D²NA code in console.

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
  # Run D²NA code in console. Read input signals from STDIN and write to
  # STDOUT.
  class Console
    # Code object for this session.
    attr_reader :code
    
    # Input stream to read signals (default is +STDIN+).
    attr_accessor :input
    
    # Output stream to print signals (default is +STDOUT+).
    attr_accessor :output
    
    # Write prompt to console: <tt>></tt> before output and <tt><</tt> before
    # input signals.
    attr_accessor :prompt
    
    # Create Code object.
    def initialize
      @code = Code.new
      @input = STDIN
      @output = STDOUT
      @prompt = false
      @code.listen &method(:print)
    end
    
    # Parse +string+ and load rules for Code object.
    def load(string)
      rules = eval("proc { #{string} }")
      @code.instance_eval &rules
    end
    
    # Print output signal to output stream.
    def print(code, signal)
      if @prompt
        @output << '> '
      end
      @output << signal.to_s << "\n"
    end
    
    # Read input signal from input stream.
    def read
      if @prompt
        @output << '< '
      end
      signal = parse_signal @input.readline
      @code << signal if signal
    end
    
    # Remove leading and trailing whitespaces, capitalize and convert to Symbol.
    def parse_signal(text)
      text.strip!
      return if text.empty?
      text = text[1..-1] if ':' == text[0..0]
      text.capitalize!
      text.to_sym
    end
  end
end
