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
    }.should raise_error ArgumentError, /capitalized/
  end
  
  it "should add new output signal" do
    code = D2NA::Code.new do
      output :One, :One, :Two
    end
    code.output_signals.should == [:One, :Two]
  end
  
end
