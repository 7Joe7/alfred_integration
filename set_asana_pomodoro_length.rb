# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {:action => 'Set Pomodoro length'}
communicate do
  if @input.to_i > 0
    @config[:asana] ||= {}
    @config[:asana][:pomodoro_length] = @input.to_i
    puts 'Pomodoro length set.'
  else
    puts 'Use format of number of minutes in one Pomodoro.'
  end
end