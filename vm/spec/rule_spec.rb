# encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Rule do
  
  it "should store conditions" do
    rule = D2NA::Rule.new [:Input, :state]
    rule.conditions.should == [:Input, :state]
  end
  
  it "should store commands" do
    rule = D2NA::Rule.new [:Input, :state] do
      up :state
      down :state
      send :"Output1"
    end
    rule.commands.should == [[:up, :state], [:down, :state], [:send, :Output1]]
  end
  
  it "should run commands on owner" do
    code = mock('code', null_object: true)
    
    code.should_receive(:state_up).with(:state).ordered
    code.should_receive(:send_out).with(:Output).ordered
    code.should_receive(:state_down).with(:state).ordered
    
    rule = D2NA::Rule.new [] do
      up :state
      send :Output
      down :state
    end
    rule.call(code)
  end
  
  it "shouldn't has code injection" do
    rule = D2NA::Rule.new [:Input, :state] do
      @commands << [:send, :Signal_Name_0]
    end
      
    lambda {
      rule = D2NA::Rule.new [:Input, :state] do
        @commands << [:'raise Error', :'raise Error;raise']
      end
    }.should raise_error SecurityError
  end
  
end
