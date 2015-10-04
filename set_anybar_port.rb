# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = parse_input(@input, [:low, :high]).merge(:action => 'Set Anybar Port Range')
ports = File.exists?(PORTS_PATH) ? JSON.parse(File.read(PORTS_PATH), :symbolize_names => true) : []
low, high = @params[:low].to_i, @params[:high].to_i
if low && high
  ports = (low..high).to_a.uniq
  puts 'Anybar Port Range Is Set.'
else
  puts "Input Wasn't in Correct Format."
end
File.write(PORTS_PATH, JSON.pretty_unparse(ports))