# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'pursue_habit', :id => @input.to_i}
communicate do
  @now ||= Time.now
  @today ||= Time.new(@now.year, @now.month, @now.day)
  update_habit do |habit|
    if habit[:active]
      # quit_habit_port(habit) if @config[:asana][:anybar_active]
      habit[:active] = false
      habit[:actual] = 0
      habit[:deadline] = nil
      habit[:repetition] = nil
      habit[:start] = nil
      habit[:done] = nil
      habit[:only_on_deadline] = false
    else
      # start_habit_port(habit) if @config[:asana][:anybar_active]
      habit[:active] = true
      habit[:repetition] = @repetition
      if habit[:repetition] == 'daily'
        habit[:deadline] = @today + 86400
      elsif habit[:repetition] == 'weekly'
        habit[:deadline] = @today + 7 * 86400
        habit[:only_on_deadline] = true
      end
      habit[:start] = @today
    end
    @result = "Habit #{habit[:name]} set to #{habit[:active] ? 'pursued' : 'not pursued'}"
  end
end