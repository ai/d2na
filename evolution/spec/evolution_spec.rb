require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Evolution do
  
  it "should create tests" do
    test = lambda {}
    evolution = D2NA::Evolution.new do
      selection 'first', :priority => 2, &test
      selection 'second', &test
      selection :priority => 0.5, &test
      selection &test
    end
    
    evolution.tests.tests.should == [[test, 'first', 2],
                                     [test, 'second', nil],
                                     [test, nil, 0.5],
                                     [test, nil, nil]]
  end
  
  it "should raise error on test without block" do
    lambda {
      evolution = D2NA::Evolution.new do
        selection
      end
    }.should raise_error ArgumentError, /must have block/
  end
  
end
