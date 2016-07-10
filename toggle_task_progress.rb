# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

if @input[0] == 'w'
  type = :work_project
  id = @input[1..-1]
else
  type = :next_project
  id = @input
end
@params = { :task_id => id, :time => Time.now, :action => 'toggle_task_progress', :label => 'Toggle task progress status', :type => type}
communicate { toggle_task_progress(@params) }