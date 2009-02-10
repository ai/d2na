# encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Worker do
  
  it "should save evolution and clone tests" do
    evolution = D2NA::Evolution.new do
      selection 'test' do
      end
    end
    worker = D2NA::Worker.new(evolution)
    
    worker.evolution.should == evolution
    worker.tests.should_not equal(evolution.tests)
    worker.tests.tests.length.should == 1
    worker.tests.tests[0][1].should == 'test'
  end
  
end
