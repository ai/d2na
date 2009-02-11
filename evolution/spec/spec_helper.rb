# encoding: utf-8
require File.join(File.dirname(__FILE__), '../lib/d2na-evolution')

def fake_code
  code = D2NA::MutableCode.new
  code.stub!(:clone).and_return(code)
  code.stub!(:mutate!)
  code
end
