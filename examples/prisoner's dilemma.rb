#!/usr/bin/env ruby1.9.1

require '../evolution/lib/d2na-evolution'

punishments = {
  [:Keep,   :Keep]   => [ 1,  1],
  [:Betray, :Keep]   => [ 0, 10],
  [:Keep,   :Betray] => [10,  0],
  [:Betray, :Betray] => [ 5,  5]
}

opponents = {
  good: proc { :Keep },
  bad:  proc { :Betray }
}

def input_name(output)
  "#{output}ed".to_sym
end

evolution = D2NA::Evolution.new do
  protocode do
    input  :Step, :Keeped, :Betrayed
    output :Keep, :Betray
  end
  
  end_if { stagnation > 5 }
  
  opponents.each do |name, opponent|
    selection name do
      our_punishment = 0
      opponent_choice = nil
      
      5.times do
        clear_out!
        send :Step
        our_choice = out.first
        
        unless our_choice
          our_punishment = 100
          break
        end
        
        opponent_choice = opponent.call
        send input_name(opponent_choice)
        
        our_punishment += punishments[[our_choice, opponent_choice]].first
      end
      
      min our_punishment
    end
  end
end

while evolution.next_step?
  evolution.step!
  putc '.'
end

puts "\n"
puts evolution.population.best.to_ruby
