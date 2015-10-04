# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Refresh cache activation toggle'}
communicate do
  if @input == 'true'
    @config[:asana][:refresh_cache_active] = true
    puts 'Cache Synchronisation activated.'
  else
    @config[:asana][:refresh_cache_active] = false
    puts 'Cache Synchronisation deactivated.'
  end
end