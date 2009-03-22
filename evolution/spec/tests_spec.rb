# encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Tests do
  
  before do
    @tests = D2NA::Tests.new
    @code = D2NA::Code.new do
      on :Input do
        send :Output
      end
      on :A do
        send :B
      end
    end
    @out = D2NA::Recorder.new(@code)
  end
  
  it "should store and run tests" do
    @tests.add('my test', 2) { }
    @tests.add { }
    
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
    result = @tests.run(@code)
    
    result.should have(1).tests
    result.should have(1).to_max
    result.should have(1).to_min
    
    result.score.should == 2
    result.sum_to_min.should == 2
    result.sum_to_max.should == 20
  end
  
  it "should has shortcuts with priority" do
    @tests.add do
      should 1 == 1, priority: 3
      min 1, priority: 3
      max 10, priority: 3
    end
    result = @tests.run(@code)
    
    result.score.should == 3
    result.sum_to_min.should == 3
    result.sum_to_max.should == 30
  end
  
  it "should send signals to code" do
    @tests.add do
      send :Input, :A
    end
    @tests.run(@code)
    
    @out.should == [:Output, :B]
  end
  
  it "should match all output signals count" do
    @tests.add do
      send :Input, :Input, :A
      out_should Output: 2, priority: 3
    end
    result = @tests.run(@code)
    
    result.should_not be_success
    result.should have(2).tests
    result.should have(2).to_min
    
    result.score.should == 3
    result.sum_to_min.should == 3
  end
  
  it "should match some output signals count" do
    @tests.add do
      send :Input, :Input, :A
      out_should_has Output: 2, priority: 2
    end
    result = @tests.run(@code)
    
    result.should be_success
    result.should have(1).tests
    result.should have(1).to_min
    
    result.score.should == 2
    result.sum_to_min.should == 0
  end
  
  it "should match, that out doesn't contain some signals" do
    @tests.add do
      send :A, :A
      out_should_hasnt :Output, :B, priority: 2
      out_should_hasnt :B
    end
    result = @tests.run(@code)
    
    result.should_not be_success
    result.should have(3).tests
    result.should have(3).to_min
    
    result.score.should == 2
    result.sum_to_min.should == 6
  end
  
  it "should match empty out" do
    @tests.add nil, 3 do
      out_should_be_empty priority: 2
      send :Input
      out_should_be_empty
    end
    result = @tests.run(@code)
    
    result.should_not be_success
    result.should have(2).tests
    result.should have(2).to_min
    result.score.should == 2
    result.sum_to_min.should == 3
  end
  
  it "should clear out" do
    @tests.add do
      send :Input, :A
      clear_out!
    end
    @tests.run(@code)
    
    @tests.out.should be_empty
    @tests.output_signals.should be_empty
  end
  
  it "should start code before test" do
    @code = D2NA::Code.new do
      on :Init do
        send :Output
      end
    end
    @tests.add do
      out_should Output: 1
    end
    result = @tests.run(@code)
    
    result.should be_success
  end
  
end
