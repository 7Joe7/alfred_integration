# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'delete_habit', :id => @input.to_i }
communicate do
  habits = load_habits
  habit = habits.find { |habit| habit[:id] == @params[:id] }
  quit_habit_port(habit) if @config[:asana][:anybar_active]
  habits.delete(habit)
  save_habits(habits)
  delete_task(habit[:id])
  @result += "Habit #{habit[:name]} deleted"
end