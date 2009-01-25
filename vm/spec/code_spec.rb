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
    
    code.should have(2).rules
    
    code.rules[0].conditions.should == [:Input]
    code.rules[0].commands.should == [[:up, :state], [:send, :Output]]
    
    code.rules[1].conditions.should == [:Input, :state]
    code.rules[1].commands.should == [[:down, :state]]
  end
  
  it "should add new input signal" do
    code = D2NA::Code.new
    code.input(:One, :Two, :One).should == [:One, :Two]
    code.input_signals.should == [:Init, :One, :Two]
  end
  
  it "should raise error if input signal isn't capitalized" do
    code = D2NA::Code.new
    lambda {
      code.input :bad
    }.should raise_error ArgumentError, /must be capitalized/
  end
  
  it "should add new output signal" do
    code = D2NA::Code.new
    code.output(:One, :One, :Two).should == [:One, :Two]
    code.output_signals.should == [:One, :Two]
  end
  
  it "should add new state" do
    code = D2NA::Code.new
    code.add_states(:one, :one, :two).should == [:one, :two]
    code.should have(2).states
  end
  
  it "should raise error if state if capitalized" do
    code = D2NA::Code.new
    lambda {
      code.add_states :Bad
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
    
    code.input_signals.should == [:Init, :Input]
    code.output_signals.should == [:Output]
    code.states.keys.should == [:state]
  end
  
  it "should create conditions cache" do
    code = D2NA::Code.new do
      input :Big
      add_states :one
      on :Small, :one, :two do
        up :three
      end
    end
    
    code.conditions_cache.should == {
      :Init  => [],
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
  
  it "should delete listeners" do
    code = D2NA::Code.new do
      on :Input do
        send :Output
      end
    end
    mock = mock('listener', :dispatch => true)
    code.listen &mock.method(:dispatch)
    
    code.delete_listeners!
    
    mock.should_not_receive(:dispatch)
    code << :Input
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
    out = D2NA::Recorder.new(code)
    
    code << :Input
    out.should == [:One]
  end
  
  it "should run rule on input signals and states" do
    code = D2NA::Code.new do
      on :Input do
        send :Get
        up :state
      end
      on :Input, :state do
        send :State
        down :state
        down :state
      end
    end
    out = D2NA::Recorder.new(code)
    
    code << :Input
    out.should == [:Get]
    code.states[:state].should == 1
    out.clear
    
    code << :Input
    out.should == [:Get, :State]
    code.states[:state].should == 0
  end
  
  it "should run rule by state" do
    code = D2NA::Code.new do
      on :Save do
        up :memory
      end
      on :Print do
        up :print
      end
      on :print, :memory do
        send :Output
        down :memory
      end
    end
    out = D2NA::Recorder.new(code)
    
    code << :Save << :Save << :Save
    code << :Print
    out.should == [:Output, :Output, :Output]
  end
  
  it "should start rules as layers" do
    code = D2NA::Code.new do
      on :First do
        up :start
      end
      on :Input do
        up :state
        down :start
      end
      on :Input, :start do
        up :start
        down :state
      end
      on :state do
        send :Bad
        down :state
      end
    end
    out = D2NA::Recorder.new(code)
    
    code << :First
    code << :Input
    out.should be_empty
  end
  
  it "should has initialization signal" do
    code = D2NA::Code.new do
      on :Init do
        send :Started
      end
      on :Input do
        send :Work
      end
    end
    
    out = D2NA::Recorder.new(code)
    code.started?.should be_false
    code.start
    out.should == [:Started]
    code.started?.should be_true
    code.reset!
    
    out = D2NA::Recorder.new(code)
    code << :Input
    out.should == [:Started, :Work]
    code.started?.should be_true
  end
  
  it "should reset states" do
    code = D2NA::Code.new do
      on :Init do
        up :memory
      end
      on :Input do
        up :memory
      end
    end
    code << :Input
    
    code.reset!
    
    code.started?.should be_false
    code.states[:memory].should == 0
    
    code << :Input
    code.started?.should be_true
    code.states[:memory].should == 2
  end
  
  it "should be protected from infinite recursion" do
    code = D2NA::Code.new do
      on :Init do
        up :infinity
      end
      on :infinity do
        up :infinity
      end
    end
    code.start
  end
  
  it "should return command count" do
    code = D2NA::Code.new do
      on :Input do
        up :state
        send :Output
      end
      on :Input, :state do
        down :state
      end
    end
    
    code.length.should == 3
  end
  
end
