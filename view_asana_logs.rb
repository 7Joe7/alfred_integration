# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

items = Nokogiri::XML(File.read(VIEW_LOGS_ADDRESS))
if items.xpath('//items/item').empty?
  root_node = items.xpath('//items').first
  root_node.add_child('<item arg="" valid="no"><title>No Logs for this Query</title><subtitle/><icon>icon.png</icon></item>')
end
puts items.to_xml