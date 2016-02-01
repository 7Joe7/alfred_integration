# encoding: UTF-8

require 'nokogiri'

PROCESS = 'Habits Feature'

builder = Nokogiri::XML::Builder.new do |xml|
  xml.items do
    xml.item('arg' => 'true') do
      xml.title "Activate #{PROCESS}"
      xml.subtitle "#{PROCESS} synchronisation will run on hotkey (by default Alt+S) or external trigger."
      xml.icon 'icon.png'
    end
    xml.item('arg' => 'false') do
      xml.title "Deactivate #{PROCESS}"
      xml.subtitle "#{PROCESS} synchronisation will NOT run on hotkey (by default Alt+S) or external trigger."
      xml.icon 'icon.png'
    end
  end
end

puts builder.to_xml