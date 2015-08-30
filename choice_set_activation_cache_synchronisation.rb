# encoding: UTF-8

require 'nokogiri'

PROCESS = 'Cache Synchronisation'

builder = Nokogiri::XML::Builder.new do |xml|
  xml.items do
    xml.item('arg' => 'true') do
      xml.title "Activate #{PROCESS}"
      xml.subtitle "#{PROCESS} will run on hotkey (by default Alt+S) or external trigger."
      xml.icon 'icon.png'
    end
    xml.item('arg' => 'false') do
      xml.title "Deactivate #{PROCESS}"
      xml.subtitle "#{PROCESS} will NOT run on hotkey (by default Alt+S) or external trigger."
      xml.icon 'icon.png'
    end
  end
end

puts builder.to_xml