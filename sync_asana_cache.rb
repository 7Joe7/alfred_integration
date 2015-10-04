# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Refresh Asana cache'}
communicate do
  sync_cache if @config[:asana][:refresh_cache_active]
  @result = 'Asana cache syncronised.'
end