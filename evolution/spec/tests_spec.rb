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
    
    @tests.tests.length.should == 2
    @tests.tests[0][1].should == 'my test'
    @tests.tests[0][2].should == 2
    @tests.tests[1][1].should == nil
    @tests.tests[1][2].should == 1
  end
  
  it "should run tests" do
    my_code = D2NA::Code.new
    @tests.add do
      result.match(code.should == my_code)
    end
    result = @tests.run(my_code)
    
    result.should be_success
    result.should have(1).tests
  end
  
  it "should has shortcuts" do
    @tests.add nil, 2 do
      should 1 == 1
      min 1
      max 10
    end
    result = @tests.run(nil)
    
    result.should have(1).tests
    result.should have(1).to_max
    result.should have(1).to_min
    
    result.score.should == 2
    result.sum_to_min.should == 2
    result.sum_to_max.should == 20
  end
  
  it "should has shortcuts with priority" do
    @tests.add do
      should 1 == 1, :priority => 3
      min 1, :priority => 3
      max 10, :priority => 3
    end
    result = @tests.run(nil)
    
    result.score.should == 3
    result.sum_to_min.should == 3
    result.sum_to_max.should == 30
  end
  
end
