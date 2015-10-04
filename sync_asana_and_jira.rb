# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Synchronise Asana and Jira'}
communicate do
  if @config[:jira] && @config[:jira][:credentials] && @config[:jira][:credentials][:username] && @config[:jira][:credentials][:password] && @config[:jira][:credentials][:hostname]
    insert_from_jira_into_asana
    @result = 'Asana and Jira are synchronised.'
  else
    @result = 'Set Jira credentials first.'
  end
end