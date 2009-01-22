require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::TestResult do
  
  before do
    @one = D2NA::TestResult.new
    @two = D2NA::TestResult.new
  end
  
  it "should be success on all success boolean tests" do
    @one.should be_success
    
    @one.max 0
    @one.should be_success
    
    @one.match false, 0.1
    @one.should_not be_success
    
    @one.match true
    @one.should_not be_success
  end
  
  it "should compare boolean tests before max and min value" do
    @one.match true
    @one.max 0
    
    @two.match false
    @two.max 10000
    
    @one.should > @two
  end
  
  it "should compare min value if boolean tests is equal" do
    @one.match true
    @one.max 2
    
    @two.match true
    @two.max 1
    
    @one.should > @two
  end
  
  it "should compare max value if boolean tests is equal" do
    @one.match true
    @one.min 1
    
    @two.match true
    @two.min 0
    
    @one.should < @two
  end
  
  it "should use priority on score compare" do
    @one.match true, 1
    @two.match true, 0.9
    
    @one.should > @two
  end
  
  it "should use priority on compare min and max values" do
    @one.max 1, 1
    @one.min 1, 0.5
    
    @two.max 0, 1
    @two.min -1, 0.5
    
    @one.should == @two
  end
  
end
