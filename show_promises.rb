# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'Show Promises' }
communicate do
  if File.exists?(PROMISES_PATH)
    load_promises
    valid_promises = @promises.find_all { |promise| promise[:name] =~ /#{@input}/i }
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.items do
        if valid_promises.empty?
          xml.item('valid' => 'no') do
            xml.title 'No promises'
            xml.subtitle ''
            xml.icon 'picture/black@2x.png'
          end
        end
        valid_promises.each { |promise| promise_to_xml(xml, promise) }
      end
    end
    puts builder.to_xml
  else
    actualize_tags unless @config[:asana][:tags][:promise]
    if @config[:asana][:tags][:promise]
      @promises = []
      tasks = get_tasks_by_tag(:promise)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.items do
          tasks.each do |task|
            @promises << to_promise(task)
            promise_to_xml(xml, @promises.last)
          end
        end
      end
      save_promises
      puts builder.to_xml
    else
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.items do
          xml.item('valid' => 'no') do
            xml.title "You don't have a Promise tag"
            xml.subtitle 'Create the tag in Asana first'
            xml.icon 'pictures/black@2x.png'
          end
        end
      end
      puts builder.to_xml
    end
  end
end