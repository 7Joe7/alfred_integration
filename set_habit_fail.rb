# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'set_habit_undone', :id => @input.to_i }
communicate do
  habit = update_habit(@params) do |habit, habits|
    fail_habit(habit)
    quit_habit_port(habit) if @config[:asana][:anybar_active]
    File.write(HABITS_PATH, JSON.pretty_unparse(habits))
  end
  @result += "Habit #{habit[:name]} set as undone"
end