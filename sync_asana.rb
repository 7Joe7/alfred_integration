# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Synchronise') do
  if @config[:asana][:basic_sync_active]
    @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
    setup
  end
  insert_from_jira_into_asana if @config[:asana][:synchronise_with_jira_active]
  insert_due_today_into_today if @config[:asana][:synchronise_due_on_today_active]
  sync_cache if @config[:asana][:refresh_cache_active]
  puts 'Asana is synchronised.'
end