# encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Recorder do
  
  it "should record output signals" do
    code = D2NA::Code.new do
      on :A do
        send :B
      end
    end
    out = D2NA::Recorder.new(code)
    
    out.code.should == code
    
    out.should == []
    code << :A
    out.should == [:B]
  end
  
end
