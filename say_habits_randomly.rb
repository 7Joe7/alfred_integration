# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Habits recall') do
  actualize_tags unless @config[:asana][:tags][:habit]
  if @config[:asana][:tags][:habit]
    habits = get_tasks_by_tag(:habit)
    (0..(habits.size - 1)).to_a.shuffle.take(habits.size - 1).each { |i| `say #{habits[i]['name'].gsub("'", '')}` }
    puts 'Habits recalled.'
  else
    puts 'Create your Habit tag and refresh settings.'
  end
end
