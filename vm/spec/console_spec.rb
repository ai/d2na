require File.join(File.dirname(__FILE__), 'spec_helper')

CODE = "on :Input do\n" +
       "  send :Output\n" +
       "end"

describe D2NA::Console do
  
  it "should load code and rules" do
    console = D2NA::Console.new
    console.load CODE
    
    console.code.rules.length.should == 1
    console.code.rules[0].conditions.should == [:Input]
    console.code.rules[0].commands.should == [[:send, :Output]]
  end
  
  it "should print output signals" do
    console = D2NA::Console.new
    console.load CODE
    console.output = StringIO.new
    
    console.code << :Input
    console.output.seek(0)
    console.output.read.should == "Output\n"
  end
  
end
