# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'set_habit_done', :id => @input.to_i }
communicate do
  @now = Time.now
  habit = update_habit(@params) do |habit, habits|
    habit[:successes] += 1
    if (habit[:repetition] == 'daily' && habit[:last_streak_end_date] == @now.to_date) ||
        (habit[:repetition] == 'weekly' && (habit[:last_streak_end_date] + 604800) > habit[:deadline])
      habit[:actual] = habit[:last_streak_length]
    end
    habit[:actual] += 1
    habit[:tries] = 1 if habit[:tries] == 0
    habit[:longest] = habit[:actual] if habit[:actual] > habit[:longest]
    File.write(HABITS_PATH, JSON.pretty_unparse(habits))
  end
  @result += "Habit #{habit[:name]} set as done"
end