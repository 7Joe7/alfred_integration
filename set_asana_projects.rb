# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

begin
  params = parse_input(@input, [:inbox_project, :next_project, :someday_project, :scheduled_project])
  if params[:inbox_project] && !params[:inbox_project].empty? && params[:next_project] && !params[:next_project].empty? &&
      params[:someday_project] && !params[:someday_project].empty? && params[:scheduled_project] && !params[:scheduled_project].empty?
    if File.exists?(CONFIG_PATH)
      @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
    else
      Dir.mkdir("#{NVPREFS}#{BUNDLE_ID}") unless Dir.exists?("#{NVPREFS}#{BUNDLE_ID}")
      @config = {}
    end
    @config[:asana] ||= {}
    @config[:asana][:inbox_project] = {}
    @config[:asana][:inbox_project][:name] = params[:inbox_project]
    @config[:asana][:next_project] = {}
    @config[:asana][:next_project][:name] = params[:next_project]
    @config[:asana][:someday_project] = {}
    @config[:asana][:someday_project][:name] = params[:someday_project]
    @config[:asana][:scheduled_project] = {}
    @config[:asana][:scheduled_project][:name] = params[:scheduled_project]
    @config[:asana].delete(:my_id)
    File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
    puts 'Asana project names are set.'
  else
    puts 'Put project names in format <inbox>:<next>:<someday>:<scheduled>'
  end
rescue Exception => e
  File.write(LOGS_ADDRESS, "#{e}, #{e.backtrace}")
  puts 'Setting Asana project names failed, check format of input.'
end