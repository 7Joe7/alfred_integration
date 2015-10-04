# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = {}
communicate { for_each_project { |project| p(project); } }