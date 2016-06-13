# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Sync Habits'}
communicate do
  begin
    if @config[:asana][:anybar_active]
      port = pop_port
      if port
        start_session(port, 'Habits synchronisation is running')
        sleep 2
        anybar('cyan', port)
      end
    end
    sync_habits if @config[:asana][:habits_active]
  ensure
    if @config[:asana][:anybar_active] && port
      anybar('quit', port)
      return_port(port)
    end
  end
end
puts 'Habits synced'