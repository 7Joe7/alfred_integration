# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Refresh Asana cache') do
  sync_cache if @config[:asana][:refresh_cache_active]
  @result = 'Asana cache syncronised.'
end