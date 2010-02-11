#!/usr/bin/env ruby1.9.1
# Evolution configuration and selections to find best strategy in iterated
# prisoner's dilemma.
# 
# Program should send :Keep or :Betray on input :Step signal (or earlier,
# after previous :Step). If program send several output signal, we take first.
# Program receive opponent previous choice by input signals :Keeped and
# :Betrayed.

require '../evolution/lib/d2na-evolution'

punishments = {
  [:Keep,   :Keep]   => [ 1,  1],
  [:Betray, :Keep]   => [ 0, 10],
  [:Keep,   :Betray] => [10,  0],
  [:Betray, :Betray] => [ 5,  5]
}

opponents = {
  good:       proc { :Keep },
  bad:        proc { :Betray },
  avenger:    proc { |previous| :Betrayed == previous ? :Betray : :Keep }
}

def input_name(output)
  "#{output}ed".to_sym
end

evolution = D2NA::Evolution.new do
  protocode do
    input  :Step, :Keeped, :Betrayed
    output :Keep, :Betray
  end
  
  stagnation_grow 0
  min_population  10
  
  end_if { stagnation > 10 }
  
  opponents.values.each do |opponent|
    selection do
      our_punishment = 0
      opponent_punishment = 0
      opponent_choice, our_choice, our_previous_choice = nil
      
      10.times do
        send :Step
        our_choice = out.first
        clear_out!
        
        unless our_choice
          our_punishment = 100
          break
        end
        
        opponent_choice = opponent.call(our_previous_choice)
        send input_name(opponent_choice)
        
        our_previous_choice = input_name(our_choice)
        our_punishment += punishments[[our_choice, opponent_choice]].first
      end
      
      min our_punishment
    end
  end
end

while evolution.next_step?
  evolution.step!
  0 == evolution.stagnation ? putc('!') : putc('.')
end
puts
puts

puts evolution.population.best.to_ruby
