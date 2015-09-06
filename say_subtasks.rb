# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'say_subtasks', :id => @input) do
  subtasks = get_from_asana("tasks/#{@input}/subtasks")['data']
  if subtasks.empty?
    `say there are no subtasks of this task.`
  else
    subtasks.each { |subtask| `say #{subtask['name'].gsub(/[\(\)']/, '')}` }
  end
  @result += 'Subtasks reviewed.'
end