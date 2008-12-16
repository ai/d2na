require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Rule do
  
  it "should store conditions" do
    rule = D2NA::Rule.new [:Input, :state]
    rule.conditions.should == [:Input, :state]
  end
  
end
