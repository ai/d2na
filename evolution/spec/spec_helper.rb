# encoding: utf-8
require File.join(File.dirname(__FILE__), '../lib/d2na-evolution')

def fake_code
  code = D2NA::MutableCode.new
  code.stub!(:clone).and_return(code)
  code.stub!(:mutate!)
  code
end

module ConditionsCacheHelper
  class ConditionsCacheMatcher
    def matches?(code)
      @code = code
      @recache = {}
      @code.input_signals.each do |signal|
        @recache[signal] = []
      end
      @code.states.keys.each do |state|
        @recache[state] = []
      end
      @code.rules.each do |rule|
        rule.conditions.each do |condition|
          @recache[condition] << rule
        end
      end
      
      if @recache.keys.sort == @code.conditions_cache.keys.sort
        @recache.each_pair do |condition, rules|
          if sort(rules) != sort(@code.conditions_cache[condition])
            return false
          end
        end
        true
      else
        false
      end
    end
    
    def sort(rules)
      rules.sort do |a, b|
        a.object_id <=> b.object_id
      end
    end
    
    def failure_message
      require 'pp'
      "expected in conditions_cache:\n#{@recache.pretty_inspect}" +
        "got:\n#{@code.conditions_cache.pretty_inspect}"
    end
    
    def negative_failure_message
      require 'pp'
      "doesn't expected in conditions_cache:\n#{@recache.pretty_inspect}"
    end
  end
  
  def have_actual_conditions_cache
    ConditionsCacheMatcher.new
  end
end
