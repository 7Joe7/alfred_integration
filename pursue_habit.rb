# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'pursue_habit', :id => @input.to_i}
communicate do
  habit = update_habit(@params) do |habit, habits|
    if habit[:active]
      quit_habit_port(habit) if @config[:asana][:anybar_active]
      habit[:active] = false
      habit[:actual] = 0
      habit[:deadline] = nil
      habit[:repetition] = nil
      habit[:start] = nil
      habit[:done] = nil
    else
      start_habit_port(habit) if @config[:asana][:anybar_active]
      habit[:active] = true
      habit[:repetition] = @repetition
      if habit[:repetition] == 'daily'
        habit[:deadline] = Time.now + 86400
      elsif habit[:repetition] == 'weekly'
        habit[:deadline] = Time.now + 7 * 86400
        habit[:only_on_deadline] = true
      end
      habit[:start] = Time.now.to_date
    end
    save_habits(habits)
  end
  puts "Habit #{habit[:name]} set to #{habit[:active] ? 'pursued' : 'not pursued'}"
end