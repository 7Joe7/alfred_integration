# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Jira synchronisation activation toggle'}
communicate do
  if @input == 'true'
    @config[:asana][:synchronise_with_jira_active] = true
    puts 'Jira Synchronisation activated.'
  else
    @config[:asana][:synchronise_with_jira_active] = false
    puts 'Jira Synchronisation deactivated.'
  end
end