# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'delete_habit', :id => @input.to_i }
communicate do
  habits = JSON.parse(File.read(HABITS_PATH), :symbolize_names => true)
  habit = habits.find { |habit| habit[:id] == @params[:id] }
  quit_habit_port(habit) if @config[:asana][:anybar_active]
  habits.delete(habit)
  File.write(HABITS_PATH, JSON.pretty_unparse(habits))
  delete_task(habit[:id])
  @result += "Habit #{habit[:name]} deleted"
end