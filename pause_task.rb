# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'pause_task') { pause_task(:task_id => @input) }