# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Refresh Asana cache'}
communicate do
  if @config[:asana][:refresh_cache_active]
    sync_cache(:next_project)
    sync_cache(:work_project) if @config[:asana][:work_project] && @config[:asana][:work_project][:name]
  end
  @result = 'Asana cache syncronised.'
end