# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'set_habit_done', :id => @input.to_i }
communicate do
  update_habit do |habit|
    conquered = set_habit_done(habit)
    # quit_habit_port(habit) if @config[:asana][:anybar_active] && !habit[:opportunity]
    if conquered
      habit[:active] = false
      @result += 'Congratulations!! You have conquered this habit. It is up to you now.'
    else
      @result += "Habit #{habit[:name]} set as done"
    end
  end
end