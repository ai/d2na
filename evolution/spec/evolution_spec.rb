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
  
  it "should set protocode" do
    evolution = D2NA::Evolution.new do
      protocode do
        input :A
        output :B
      end
    end
    
    evolution.protocode.should be_an_instance_of(D2NA::MutableCode)
    evolution.protocode.input_signals.should == [:Init, :A]
    evolution.protocode.output_signals.should == [:B]
  end
  
  it "should set user protocode" do
    class MySuperCode
      def <<(signal); end
      def listen(*signlas, &block); end
      def mutate!; end
    end
    evolution = D2NA::Evolution.new do
      protocode MySuperCode.new
    end
    
    evolution.protocode.class.should == MySuperCode
  end
  
  it "should check user protocode" do
    lambda {
      evolution = D2NA::Evolution.new do
        protocode D2NA::Code.new
      end
    }.should raise_error ArgumentError, /didn't has mutate! method/
  end
  
end
