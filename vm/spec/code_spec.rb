require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Code do
  
  it "should create rule" do
    code = D2NA::Code.new do
      on :Input do
        up :state
        send :Output
      end
      
      on :Input, :state do
        down :state
      end
    end
    
    code.rules.length.should == 2
    
    code.rules[0].owner.should == code
    code.rules[0].conditions.should == [:Input]
    code.rules[0].commands.should == [[:up, :state], [:send, :Output]]
    
    code.rules[1].owner.should == code
    code.rules[1].conditions.should == [:Input, :state]
    code.rules[1].commands.should == [[:down, :state]]
  end
  
  it "should add new input signal" do
    code = D2NA::Code.new do
      input :One, :Two
      input :One
    end
    code.input_signals.should == [:One, :Two]
  end
  
  it "should raise error if input signal isn't capitalized" do
    code = D2NA::Code.new
    lambda {
      code.input :bad
    }.should raise_error ArgumentError, /must be capitalized/
  end
  
  it "should add new output signal" do
    code = D2NA::Code.new do
      output :One, :One, :Two
    end
    code.output_signals.should == [:One, :Two]
  end
  
  it "should add new state" do
    code = D2NA::Code.new do
      state :state
    end
    code.states.keys.should == [:state]
  end
  
  it "should raise error if state if capitalized" do
    code = D2NA::Code.new
    lambda {
      code.state :Bad
    }.should raise_error ArgumentError, /must not be capitalized/
  end
  
  it "should autodetect usaged signals and states" do
    code = D2NA::Code.new do
      on :Input, :state do
        down :state
        send :Output
        up :state
      end
    end
    
    code.input_signals.should == [:Input]
    code.output_signals.should == [:Output]
    code.states.keys.should == [:state]
  end
  
end
