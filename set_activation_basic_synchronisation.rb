# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Basic synchronisation activation toggle') do
  if @input == 'true'
    @config[:asana][:basic_sync_active] = true
    puts 'Basic Synchronisation activated.'
  else
    @config[:asana][:basic_sync_active] = false
    puts 'Basic Synchronisation deactivated.'
  end
end