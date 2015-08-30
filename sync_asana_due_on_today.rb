# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Synchronise due today') do
  if @config[:asana][:today_project] && @config[:asana][:today_project][:id]
    insert_due_today_into_today
    @result = 'Today tasks have been moved to today section.'
  else
    @result = 'Location for today tasks is not properly set.'
  end
end