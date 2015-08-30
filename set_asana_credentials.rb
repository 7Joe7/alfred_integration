# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

begin
  params = parse_input(@input, [:api_key, :workspace_name])
  if params[:api_key] && !params[:api_key].empty? && params[:workspace_name] && !params[:workspace_name].empty?
    if File.exists?(CONFIG_PATH)
      @config = JSON.parse(File.read(CONFIG_PATH), :symbolize_names => true)
    else
      Dir.mkdir("#{NVPREFS}#{BUNDLE_ID}") unless Dir.exists?("#{NVPREFS}#{BUNDLE_ID}")
      @config = {}
    end
    @config[:asana] ||= {}
    @config[:asana][:api_key] = params[:api_key]
    @config[:asana][:workspace_name] = params[:workspace_name]
    File.write(CONFIG_PATH, JSON.pretty_unparse(@config))
    puts 'Asana credentials are set.'
  else
    puts 'Put API key and workspace name in the right format'
  end
rescue Exception => e
  File.write(LOGS_ADDRESS, "#{e}, #{e.backtrace}")
  puts 'Setting Asana credentials failed, check format of input.'
end