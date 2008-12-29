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
    @code.rules[0].should_receive(:compile).once
    @code.rules[1].should_not_receive(:compile)
    @code.modify do
      add_command 0, :send, :Started
      add_command 0, :down, :waiting
      remove_command 2
    end
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
    
    @code.rules.length.should == 3
    @code.rules[2].conditions.should == [:waiting, :Input]
    @code.rules[2].commands.should == [[:send, :Output]]
    @code.conditions_cache[:waiting].should == [@code.rules[2]]
  end
  
  it "should delete empty rule" do
    @code.modify do
      remove_command(0)
    end
    @code.rules.length.should == 1
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
  
  it "shouldn't convert to Ruby empty rules" do
    code = D2NA::MutableCode.new do
      on :Init do
      end
      on :Input do
        send :Output
      end
    end
    
    code.to_ruby.should == "input  :Input\n" +
                           "output :Output\n" +
                           "\n" +
                           "on :Input do\n" +
                           "  send :Output\n" +
                           "end"
  end
end
