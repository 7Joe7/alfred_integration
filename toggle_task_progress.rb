# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

params = { :task_id => @input, :time => Time.now }
communicate({ :action => 'toggle_task_progress' }.merge(params)) { toggle_task_progress(params) }