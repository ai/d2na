# encoding: utf-8
=begin
Main file to load all necessary classes for D²NA evolution.

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

require 'pathname'
dir = Pathname(__FILE__).dirname.expand_path + 'd2na-evolution'

begin
  require dir + '../../../vm/lib/d2na-vm'
rescue LoadError
  puts "Error: Can't load D2NA Virtual Machine"
  exit
end

require dir + 'mutable_code'
require dir + 'test_result'
require dir + 'tests'
require dir + 'population'
require dir + 'worker'
require dir + 'timeout'
require dir + 'evolution'
