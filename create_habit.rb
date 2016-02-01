# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'create_habit', :name => @input }
communicate do
  habits = JSON.parse(File.read(HABITS_PATH), :symbolize_names => true)
  new_habit = to_habit(create_habit(@params))
  habits << new_habit
  File.write(HABITS_PATH, JSON.pretty_unparse(habits))
end