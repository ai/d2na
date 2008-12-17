require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Rule do
  
  it "should store conditions" do
    rule = D2NA::Rule.new [:Input, :state], nil
    rule.conditions.should == [:Input, :state]
  end
  
  it "should store commands" do
    rule = D2NA::Rule.new [:Input, :state], nil do
      up :state
      down :state
      send :Output
    end
    rule.commands.should == [[:up, :state], [:down, :state], [:send, :Output]]
  end
  
end
