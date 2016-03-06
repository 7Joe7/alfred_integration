# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'delete_habit', :id => @input.to_i }
communicate do
  update_habit do |habit|
    quit_habit_port(habit) if @config[:asana][:anybar_active]
    @habits.delete(habit)
    delete_task(habit[:id])
    @result += "Habit #{habit[:name]} deleted"
  end
end