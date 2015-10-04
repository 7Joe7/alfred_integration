# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'Refresh settings' }
communicate do
  @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
  setup
  puts 'Settings refreshed.'
end