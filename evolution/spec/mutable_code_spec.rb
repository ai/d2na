require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::MutableCode do
  before do
    @code = D2NA::MutableCode.new do
      on :Init do
        up :waiting
      end
      on :Input, :One do
        send :Output
        down :waiting
      end
    end
  end
  
  it "should add and remove commands" do
    @code.modify do
      add_command 0, :send, :Started
      remove_command 3
    end
    
    @code.rules[0].commands.should == [[:up, :waiting], [:send, :Started]]
    @code.rules[1].commands.should == [[:send, :Output]]
  end
  
  it "should define added output signals" do
    @code.modify do
      add_command 0, :send, :Started
    end
    @code.output_signals.should == [:Output, :Started]
  end
  
  it "should change code length on modify" do
    @code.modify do
      add_command 0, :send, :Started
      add_command 0, :down, :waiting
      remove_command 2
    end
    @code.length.should == 4
  end
  
  it "should compile modified rules" do
    one = @code.rules[0].instance_variable_get(:@compiled)
    two = @code.rules[1].instance_variable_get(:@compiled)
    
    @code.modify do
      add_command 0, :send, :Started
      add_command 0, :down, :waiting
      remove_command 2
    end
    
    @code.rules[0].instance_variable_get(:@compiled).should_not == one
    @code.rules[1].instance_variable_get(:@compiled).should == two
  end
  
  it "should has unused conditions" do
    code = D2NA::MutableCode.new do
      on :Input, :two do
        down :one
      end
    end
    
    code.conditions_count.should == 8
    code.unused_conditions.should == [Set[:Init], Set[:Input],
                                      Set[:one], Set[:one, :Input],
                                      Set[:two],
                                      Set[:one, :two], Set[:one, :two, :Input]]
  end
  
  it "should create rule from unused conditions" do
    @code.modify do
      add_command 4, :send, :Output
    end
    
    @code.should have(3).rules
    @code.rules[2].conditions.to_set.should == [:waiting, :Input].to_set
    @code.rules[2].commands.should == [[:send, :Output]]
    @code.conditions_cache[:waiting].should == [@code.rules[2]]
  end
  
  it "should delete empty rule" do
    lambda {
      @code.modify do
        remove_command(0)
      end
    }.should change(@code.unused_conditions, :length).by(1)
    @code.should have(1).rules
  end
  
  it "should convert Code to Ruby" do
    @code.to_ruby.should == "input  :Input, :One\n" +
                            "output :Output\n" +
                            "\n" +
                            "on :Init do\n" +
                            "  up :waiting\n" +
                            "end\n" +
                            "\n" +
                            "on :Input, :One do\n" +
                            "  send :Output\n" +
                            "  down :waiting\n" +
                            "end"
  end
  
  it "should clone rule" do
    code = D2NA::MutableCode.new do
      on :Input do
        up :lock
      end
      on :Input, :lock do
        send :Output
      end
    end
    code_out = D2NA::Recorder.new(code)
    
    another = code.clone
    another_out = D2NA::Recorder.new(another)
    
    code << :Input
    another << :Input
    code_out.should == []
    another_out.should == []
  end
  
  it "should clone rule on write" do
    another = @code.clone
    
    another.should_not equal(@code)
    another.parent.should equal(@code)
    
    another.rules.should_not equal(@code.rules)
    another.rules[0].should equal(@code.rules[0])
    another.rules[1].should equal(@code.rules[1])
    
    another.on :Two
    @code.should have(2).rules
    @code.should have(3).input_signals
    @code.instance_variable_get(:@exists_conditions).length.should == 2
    
    another.modify do
      add_command 0, :down, :waiting
    end
    another.rules[0].should_not equal(@code.rules[0])
    another.rules[1].should equal(@code.rules[1])
    
    another.modify do
      remove_command 2
    end
    another.rules[1].should_not equal(@code.rules[1])
  end
  
  it "should delete rule" do
    unused = @code.unused_conditions.length
    @code.delete_rule(@code.rules[1])
    @code.should have(1).rules
    @code.length.should == 1
    @code.conditions_cache[:Input].should be_empty
    @code.unused_conditions.length.should == unused + 1
  end
  
  it "should remove state" do
    code = D2NA::MutableCode.new do
      on :Init do
        send :Output
        up :waiting
      end
      on :Input, :waiting do
        send :Output
      end
    end
    code.remove_state :waiting
    
    code.states.keys.should_not include(:waiting)
    code.unused_conditions.length.should == 1
    code.conditions_cache.keys.should_not include(:waiting)
    code.should have(1).rules
    code.rules[0].commands.should == [[:send, :Output]]
  end
  
  it "should has all available commands list" do
    @code.commands.should == [[:up, :waiting], [:down, :waiting], 
                              [:send, :Output]]
  end
  
  it "should mutate commands" do
    @code.mutation_params.merge!(:add_state => 0, :remove_state => 0)
    
    @code.mutate!(:add => 1, :remove => 0, :min_actions => 3)
    @code.length.should == 6
    
    @code.mutate!(:add => 0, :remove => 1, :max_actions => 1)
    @code.length.should == 5
  end
  
  it "should mutate states" do
    @code.mutation_params.merge!(:add => 0, :remove => 0, :max_actions => 1)
    
    @code.mutate!(:add_state => 1, :remove_state => 0, :min_state_actions => 3)
    @code.should have(2).states
    @code.should have_at_least(1).rules
    @code.should have(5).commands
    
    @code.mutate!(:add_state => 0, :remove_state => 1)
    @code.should have(1).states
  end
end
