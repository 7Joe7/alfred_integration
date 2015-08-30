# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Jira synchronisation activation toggle') do
  if @input == 'true'
    @config[:asana][:synchronise_with_jira_active] = true
    puts 'Jira Synchronisation activated.'
  else
    @config[:asana][:synchronise_with_jira_active] = false
    puts 'Jira Synchronisation deactivated.'
  end
end