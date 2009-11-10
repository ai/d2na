# encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Evolution do
  
  it "should create tests" do
    test = lambda {}
    evolution = D2NA::Evolution.new do
      selection 'first', priority: 2, &test
      selection 'second', &test
      selection priority: 0.5, &test
      selection &test
    end
    
    evolution.tests.tests.should == [[test, 'first', 2],
                                     [test, 'second', 1],
                                     [test, nil, 0.5],
                                     [test, nil, 1]]
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
    class ::MySuperCode
      def <<(signal); end
      def reset!; end
      def listen(*signlas, &block); end
      def delete_listeners!; end
      def mutate!; end
    end
    evolution = D2NA::Evolution.new do
      protocode ::MySuperCode.new
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
  
  it "should create workers" do
    evolution = D2NA::Evolution.new do
      worker_count 4
    end
    
    evolution.worker_count.should == 4
    evolution.should have(4).workers
  end
  
  it "should create first population" do
    code = fake_code
    evolution = D2NA::Evolution.new do
      protocode code
      min_population 5
    end
    
    evolution.min_population.should == 5
    evolution.population.layers.should == [[code, code, code, code, code]]
  end
  
  it "should create next population" do
    code = D2NA::MutableCode.new
    clone = D2NA::MutableCode.new
    code.should_receive(:clone).exactly(2).and_return(clone)
    code.should_receive(:mutate!).exactly(0)
    clone.should_receive(:mutate!).exactly(4)
    
    evolution = D2NA::Evolution.new do
      protocode code
      min_population 2
      selection do
        should @code == clone
      end
    end
    evolution.step!
    
    evolution.population.layers.should == [[clone, clone], [code]]
  end
  
  it "should calculate stagnation" do
    code = fake_code
    evolution = D2NA::Evolution.new do
      protocode code
      selection do
        should 1 == @code.output_signals.length
      end
    end
    
    evolution.stagnation.should == 0
    evolution.step!
    evolution.stagnation.should == 1
    evolution.step!
    evolution.stagnation.should == 2
    
    code.output :A
    evolution.step!
    evolution.stagnation.should == 0
  end
  
  it "should end iterations by success" do
    tests_success = false
    evolution = D2NA::Evolution.new do
      protocode fake_code
      selection { should tests_success }
      end_if { success }
    end
    
    evolution.should_not be_end
    
    tests_success = true
    evolution.step!
    evolution.should be_end
  end
  
  it "should end iterations by stagnation" do
    evolution = D2NA::Evolution.new do
      protocode fake_code
      selection { should 1 == 0 }
      end_if { stagnation == 5 }
    end
    
    5.times do
      evolution.should_not be_end
      evolution.step!
    end
    evolution.should be_end
  end
  
  it "should return is next step is necessary" do
    tests_success = false
    evolution = D2NA::Evolution.new do
      protocode fake_code
      selection { should tests_success }
      end_if { success and stagnation > 0 }
    end
    
    evolution.next_step?.should be_true
    evolution.step!
    
    evolution.next_step?.should be_true
    tests_success = true
    evolution.step!
    
    evolution.next_step?.should be_true
    evolution.step!
    
    evolution.next_step?.should be_false
  end
  
  it "should raise error on stagnation limit" do
    evolution = D2NA::Evolution.new do
      protocode fake_code
      stagnation_limit 5
      selection { should 1 == 0 }
    end
    
    evolution.stagnation_limit.should == 5
    5.times do
      evolution.next_step?.should be_true
      evolution.step!
    end
    lambda {
      evolution.next_step?
    }.should raise_error D2NA::Timeout, /5 steps/
  end
  
  it "should generate summator" do
    evolution = D2NA::Evolution.new do
      protocode do
        input :A, :B
        output :C
      end
      stagnation_limit 10
      
      selection do
        out_should_be_empty
        send :A, :A
        out_should C: 2
        send :B, :B, :B
        out_should C: 5
      end
    end
    
    evolution.step! while evolution.next_step?
  end
  
end
