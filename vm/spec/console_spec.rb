require File.join(File.dirname(__FILE__), 'spec_helper')

CODE = "on :Input do\n" +
       "  send :Output\n" +
       "end"

describe D2NA::Console do
  before do
    @console = D2NA::Console.new
    @console.load CODE
    @console.output = ""
    @console.input = StringIO.new
  end
  
  it "should load code and rules" do
    @console.code.rules.length.should == 1
    @console.code.rules[0].conditions.should == [:Input]
    @console.code.rules[0].commands.should == [[:send, :Output]]
  end
  
  it "should print output signals" do
    @console.code << :Input
    @console.output.should == "Output\n"
  end
  
  it "should read input signals" do
    ["input", ":input", "\n", "Input"].each do |signal|
      @console.input << signal << "\n"
      @console.input.seek(0)
      @console.read
      @console.input.rewind
    end
    @console.output.should == "Output\nOutput\nOutput\n"
  end
  
  it "should print prompt" do
    @console.prompt = true
    @console.input << "Input\n"
    @console.input.seek(0)
    @console.read
    @console.output.should == "< > Output\n"
  end
  
  it "should print color prompt" do
    @console.color = true
    @console.input << "Input\n"
    @console.input.seek(0)
    @console.read
    @console.output.should == "\e[32m< \e[0m\e[31m> \e[0mOutput\n"
  end
  
end
