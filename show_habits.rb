# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'Show Habits' }
communicate do
  if @config[:asana][:habits_active]
    if File.exists?(HABITS_PATH)
      load_habits
      valid_habits = @habits.find_all { |habit| habit[:name] =~ /#{@input}/i && (@all || habit[:active]) }
      builder = Nokogiri::XML::Builder.new { |xml| xml.items do
        xml.item('valid' => 'NO') do
          xml.title "#{@score} points"
          today_valid, week_valid = [], []
          valid_habits.each do |habit|
            if habit[:repetition] == 'daily'
              today_valid << habit
            else
              week_valid << habit
            end
          end
          xml.subtitle "Today done #{(today_valid.find_all { |habit| habit[:done] }).count}/#{today_valid.count}, this week done #{(week_valid.find_all { |habit| habit[:done]}).count}/#{week_valid.count}"
          xml.icon 'pictures/special.png'
        end
        valid_habits.each { |habit| habit_to_xml(xml, habit, @all) }
      end }
      puts builder.to_xml
    else
      actualize_tags unless @config[:asana][:tags][:habit]
      if @config[:asana][:tags][:habit]
        @habits = []
        tasks = get_tasks_by_tag(:habit)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.items do
            tasks.each do |task|
              @habits << to_habit(task)
              habit_to_xml(xml, @habits.last, @all) if @all || @habits.last[:active]
            end
          end
        end
        save_habits
        puts builder.to_xml
      else
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.items do
            xml.item('valid' => 'no') do
              xml.title "You don't have a Habit tag"
              xml.subtitle 'Create the tag in Asana first'
              xml.icon 'pictures/black@2x.png'
            end
          end
        end
        puts builder.to_xml
      end
    end
  else
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.items do
        xml.item('valid' => 'no') do
          xml.title "You don't have habits feature activated"
          xml.subtitle 'Activate the feature first'
          xml.icon 'pictures/black@2x.png'
        end
      end
    end
    puts builder.to_xml
  end
end