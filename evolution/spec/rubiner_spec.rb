require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::CodeRubinerMixin do
  
  it "should convert Code to Ruby" do
    code = D2NA::Code.new do
      on :One do
        up :state
        send :Alarm
      end
      on :Two, :state do
        down :state
        send :Normal
      end
    end
    
    code.to_ruby.should == "input  :One, :Two\n" +
                           "output :Alarm, :Normal\n" +
                           "\n" +
                           "on :One do\n" +
                           "  up :state\n" +
                           "  send :Alarm\n" +
                           "end\n" +
                           "\n" +
                           "on :Two, :state do\n" +
                           "  down :state\n" +
                           "  send :Normal\n" +
                           "end"
  end
  
end
