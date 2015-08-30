# encoding: UTF-8

require 'nokogiri'

PROCESS = 'Anybar for Asana Tasks'

builder = Nokogiri::XML::Builder.new do |xml|
  xml.items do
    xml.item('arg' => 'true') do
      xml.title "Activate #{PROCESS}"
      xml.subtitle "#{PROCESS} will be used for time logging."
      xml.icon 'icon.png'
    end
    xml.item('arg' => 'false') do
      xml.title "Deactivate #{PROCESS}"
      xml.subtitle "#{PROCESS} will NOT be used for time logging."
      xml.icon 'icon.png'
    end
  end
end

puts builder.to_xml