# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'set_habit_done', :id => @input.to_i }
communicate do
  update_habit do |habit|
    set_habit_done(habit)
    quit_habit_port(habit) if @config[:asana][:anybar_active]
    @result += "Habit #{habit[:name]} set as done"
  end
end