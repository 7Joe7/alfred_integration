# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Habits feature activation toggle'}
communicate do
  if @input == 'true'
    @config[:asana][:habits_active] = true
    puts 'Habits feature activated.'
  else
    @config[:asana][:habits_active] = false
    puts 'Habits feature deactivated.'
  end
end