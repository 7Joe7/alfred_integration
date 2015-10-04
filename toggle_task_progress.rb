# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :task_id => @input, :time => Time.now, :action => 'toggle_task_progress', :label => 'Toggle task progress status' }
communicate { toggle_task_progress(@params) }