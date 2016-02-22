# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'create_habit', :name => @input }
communicate do
  habits = load_habits
  new_habit = to_habit(create_habit(@params))
  habits << new_habit
  save_habits(habits)
end