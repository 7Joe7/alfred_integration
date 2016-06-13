# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'set_habit_undone', :id => @input.to_i }
communicate do
  update_habit do |habit|
    fail_habit(habit)
    unless habit[:opportunity]
      habit[:done] = false
      # quit_habit_port(habit) if @config[:asana][:anybar_active]
    end
    @result += "Habit #{habit[:name]} set as undone"
  end
end