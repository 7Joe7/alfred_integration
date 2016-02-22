# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'set_habit_done', :id => @input.to_i }
communicate do
  habit = update_habit(@params) do |habit, habits|
    habit_done(habit)
    quit_habit_port(habit) if @config[:asana][:anybar_active]
    save_habits(habits)
  end
  @result += "Habit #{habit[:name]} set as done"
end