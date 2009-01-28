=begin
Control evolution for D²NA code.

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
  # Evolution controller.
  class Evolution
    # Code tests, which will direct evolution.
    attr_accessor :tests
    
    # Create new evolution. You can configure it in block, which will be eval
    # on new instance.
    def initialize(&block)
      @tests = Tests.new
      instance_eval(&block) if block_given?
    end
    
    # Add new test for code, which will direct evolution. This test didn’t say
    # only success or fail, it say that some code has result better than
    # another, even if they are success or fail together.
    #
    # First argument is test description, like in RSpec. In second you can set
    # <tt>:priority</tt> with value. In block you can use:
    # * <tt>send :Signal</tt> to send signal to testing code;
    # * <tt>out_should :Signal => count</tt> to match all sent output signals
    #   counts;
    # * <tt>out_should_has :Signal => count</tt> to match only selected output
    #   signals;
    # * <tt>out_should_hasnt :Signal</tt> to match that this output signals
    #   isn’t be sent.
    # * <tt>out_should_be_empty</tt> to match, that out is empty;
    # * <tt>clear_out</tt> to clear output signals queue for <tt>out_*</tt>
    #   matchers;
    # * <tt>should out.length == 5</tt> to match some boolean test;
    # * <tt>min value</tt> to select code, that has minimum value;
    # * <tt>max value</tt> to select code, that has maximum value.
    # In all matchers (<tt>out_*</tt>, +should+ and +min+/+max+) you can set
    # <tt>:priority</tt> with value. See Tests documentation for all available
    # methods and information. 
    #
    # == Usage
    # 
    #   selection "example test", :priority => 2 do
    #     out_should_be_empty
    #     send :A, :A, :B
    #     out_should_has :A => 2, :B => 1
    #     out_should_has :B => 1
    #     clear_out
    #     send :A
    #     out_should_hasnt :B, :priority => 4
    #     should out.length == 1
    #     min code.length, :priority => 0.5
    #   end
    def selection(description = nil, options = {}, &block)
      raise ArgumentError, 'Test must have block with code' unless block_given?
      if Hash == description.class and options.empty?
        options = description
        description = nil
      end
      @tests.add(description, options[:priority], &block)
    end
  end
end
