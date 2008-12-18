require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Console do
  
  it "should load code and rules" do
    console = D2NA::Console.new
    console.load "on :Input do\n" +
                 "  send :Output\n" +
                 "end"
    
    console.code.rules.length.should == 1
    console.code.rules[0].conditions.should == [:Input]
    console.code.rules[0].commands.should == [[:send, :Output]]
  end
  
end
