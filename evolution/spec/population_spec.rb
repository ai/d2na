# encoding: utf-8
require File.join(File.dirname(__FILE__), 'spec_helper')

describe D2NA::Population do
  
  it "should fill itself" do
    code = D2NA::Code.new
    result = D2NA::TestResult.new
    population = D2NA::Population.new(5, code, result)
    
    population.results.should == [result]
    population.layers.should == [[code, code, code, code, code]]
  end
  
  it "should add new code" do
    population = D2NA::Population.new
    population.push(1, 1.0)
    population.push(3, 3.0)
    population.push(2, 2.0)
    population.push(1, 1.0)
    population.push(4, 4.0)
    population.push(1, 1.0)
    population.push(2, 2.0)
    
    population.results.should == [4.0, 3.0, 2.0, 1.0]
    population.layers.should == [[4], [3], [2, 2], [1, 1, 1]]
    
    population.best_result.should == 4.0
  end
  
  it "should pop last code" do
    population = D2NA::Population.new
    population.push(1, 1.0)
    population.push(2, 2.0)
    population.push(3, 3.0)
    population.push(2, 2.0)
    
    population.pop.should == 1
    population.pop.should == 2
    population.pop.should == 2
    population.pop.should == 3
  end
  
  it "should trim population" do
    population = D2NA::Population.new
    population.push(1, 1.0)
    population.push(2, 2.0)
    population.push(2, 2.0)
    population.push(3, 3.0)
    population.push(3, 3.0)
    population.push(3, 3.0)
    population.push(4, 4.0)
    population.push(4, 4.0)
    population.push(4, 4.0)
    
    population.trim(4, 2)
    population.layers.should == [[4, 4, 4], [3, 3], [2]]
  end
  
end
