# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'create_habit', :name => @input }
communicate do
  load_habits
  @habits << create_habit(@params)
  save_habits
end