require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Tests do
  
  before do
    @tests = D2NA::Tests.new
  end
  
  it "should store tests" do
    @tests.add 'my test', 2 do
      result.match(false)
    end
    @tests.add do
      result.match(true)
    end
    
    @tests.should have(2).tests
    @tests.tests[0][1].should == 'my test'
    @tests.tests[0][2].should == 2
    @tests.tests[1][1].should == nil
    @tests.tests[1][2].should == 1
  end
  
end
