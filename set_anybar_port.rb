# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

params = parse_input(@input, [:low, :high])
communicate(:action => 'Set Anybar Port Range') do
  low, high = params[:low].to_i, params[:high].to_i
  if low && high
    @config[:anybar][:ports] = (low..high).to_a.uniq
    @result = 'Anybar Port Range Is Set.'
  else
    @result = "Input Wasn't in Correct Format."
  end
end