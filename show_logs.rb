# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

now = Time.now
days_time, days = [now], []
(1..6).each { |i| days_time << now - i * 86400 }
days_time.each_with_index do |day_time, i|
  day = []
  day << if i == 0
           'Today'
         elsif i == 1
           'Yesterday'
         else
           day_time.strftime('%A')
         end
  day << day_time.strftime(LOG_DATE_FORMAT)
  days << day
end
builder = Nokogiri::XML::Builder.new do |xml|
  xml.items do
    xml.item('arg' => @input, 'valid' => @input =~ /^\d{4}-\d{2}-\d{2}$/ ? 'yes' : 'no') do
      xml.title 'Filter Logs by Date'
      xml.subtitle 'Shows logs ON date. Use format YYYY-MM-DD, e.g. 2015-07-05.'
      xml.subtitle 'Shows logs SINCE date. Use format YYYY-MM-DD, e.g. 2015-07-05.', 'mod' => 'cmd'
      xml.icon 'icon.png'
    end
    days.each do |day|
      xml.item('arg' => day[1]) do
        xml.title day[0]
        xml.subtitle "Shows logs ON #{day[1]}."
        xml.subtitle "Shows logs SINCE #{day[1]}.", 'mod' => 'cmd'
      end
    end
    xml.item('arg' => 'Iever') do
      xml.title 'Show Overall Logged Time on Incomplete Tasks'
      xml.subtitle ''
      xml.icon 'icon.png'
    end
    xml.item('arg' => 'Cever') do
      xml.title 'Show Overall Logged Time on Completed Tasks'
      xml.subtitle ''
      xml.icon 'icon.png'
    end
    xml.item('arg' => 'ever') do
      xml.title 'Show Overall Logged Time on All Tasks'
      xml.subtitle ''
      xml.icon 'icon.png'
    end
  end
end
puts builder.to_xml