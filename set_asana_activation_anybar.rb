# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Anybar activation toggle'}
communicate do
  if @input == 'true'
    @config[:asana][:anybar_active] = true
    puts 'Anybar for Asana Tasks activated.'
  else
    @config[:asana][:anybar_active] = false
    puts 'Anybar for Asana Tasks deactivated.'
  end
end