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
  
  it "should create conditions cache" do
    code = D2NA::Code.new do
      input :Big
      state :one
      on :Small, :one, :two do
        up :three
      end
    end
    
    code.conditions_cache.should == {
      :Big   => [],
      :Small => [code.rules.first],
      :one   => [code.rules.first],
      :two   => [code.rules.first],
      :three => []
    }
  end
  
  it "should send output signals to listeners" do
    code = D2NA::Code.new
    code.output :One, :Two
    
    mock = mock('listener')
    mock.should_receive(:one).with(code, :One)
    mock.should_receive(:both).with(code, :One)
    mock.should_receive(:all).with(code, :One)
    mock.should_not_receive(:two)
    
    code.listen :One, &mock.method(:one)
    code.listen :Two, &mock.method(:two)
    code.listen :One, :Two, &mock.method(:both)
    code.listen &mock.method(:all)
    
    code.send_out :One
  end
  
  it "should run rule on input signal" do
    code = D2NA::Code.new do
      on :Input do
        send :One
      end
      on :Input, :state do
        send :Two
      end
    end
    
    mock = mock('listener')
    mock.should_receive(:one).with(code, :One)
    mock.should_not_receive(:two)
    code.listen :One, &mock.method(:one)
    code.listen :Two, &mock.method(:two)
    
    code.send_in :Input
  end
  
end
