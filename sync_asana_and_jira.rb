# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Synchronise Asana and Jira') do
  if @config[:jira] && @config[:jira][:credentials] && @config[:jira][:credentials][:username] && @config[:jira][:credentials][:password] && @config[:jira][:credentials][:hostname]
    insert_from_jira_into_asana
    @result = 'Asana and Jira are synchronised.'
  else
    @result = 'Set Jira credentials first.'
  end
end