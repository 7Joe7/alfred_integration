# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Synchronise'}
communicate do
  begin
    if @config[:asana][:anybar_active]
      port = pop_port
      if port
        start_session(port, 'Asana synchronisation is running')
        sleep 2
        anybar('cyan', port)
      end
    end
    setup if @config[:asana][:basic_sync_active]
    sync_habits if @config[:asana][:habits_active]
    if @config[:asana][:refresh_cache_active]
      sync_cache(:next_project)
      sync_cache(:work_project) if @config[:asana][:work_project] && @config[:asana][:work_project][:name]
    end
    begin
      insert_from_jira_into_asana if @config[:asana][:synchronise_with_jira_active]
    rescue SocketError
      @result += 'Jira syncronisation failed due to bad connection (VPN?). '
    end
    insert_due_today_into_today if @config[:asana][:synchronise_due_on_today_active]
    puts 'Asana is synchronised.'
  ensure
    if @config[:asana][:anybar_active] && port
      anybar('quit', port)
      return_port(port)
    end
  end
end