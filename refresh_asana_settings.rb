# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Refresh settings') do
  @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
  setup
  puts 'Settings refreshed.'
end