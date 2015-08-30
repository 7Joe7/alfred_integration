# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

communicate(:action => 'Anybar activation toggle') do
  if @input == 'true'
    @config[:asana][:anybar_active] = true
    puts 'Anybar for Asana Tasks activated.'
  else
    @config[:asana][:anybar_active] = false
    puts 'Anybar for Asana Tasks deactivated.'
  end
end