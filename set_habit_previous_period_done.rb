# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'set_habit_done', :id => @input.to_i }
communicate do
  @now ||= Time.now
  update_habit do |habit|
    habit[:successes] += 1
    if (habit[:repetition] == 'daily' && (habit[:last_streak_end_date] + 86400) >= habit[:deadline]) ||
        (habit[:repetition] == 'weekly' && (habit[:last_streak_end_date] + 604800) >= habit[:deadline])
      habit[:actual] = habit[:last_streak_length] + habit[:actual]
    end
    habit[:actual] += 1
    habit[:tries] = 1 if habit[:tries] == 0
    habit[:longest] = habit[:actual] if habit[:actual] > habit[:longest]
    @score += (habit[:actual] + 1) * (10 - habit[:priority])
    @result += "Habit #{habit[:name]} set as done"
  end
end