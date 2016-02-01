# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Sync Habits'}
communicate do
  sync_habits if @config[:asana][:habits_active]
end
puts 'Habits synced'