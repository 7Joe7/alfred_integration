# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'pause_task', :label => 'Pause of task', :task_id => @input}
communicate { pause_task(@params) }