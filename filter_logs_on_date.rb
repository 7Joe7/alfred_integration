# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

params, tasks = process_log_filter_input(@input, false), {}
filter_logs(tasks, params)