# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Due on today synchronisation activation toggle') do
  if @input == 'true'
    @config[:asana][:synchronise_due_on_today_active] = true
    puts 'Due on Today Synchronisation activated.'
  else
    @config[:asana][:synchronise_due_on_today_active] = false
    puts 'Due on Today Synchronisation deactivated.'
  end
end