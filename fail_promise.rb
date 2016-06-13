# encoding: UTF-8

require './helpers/asana_helper.rb'

include AsanaHelper

@params = { :action => 'fail_promise', :id => @input.to_i }
communicate do
  update_promise do |promise|
    delete_task(@params[:id])
    @promises.delete(promise)
    @score -= 25
    @result += "Failed to deliver #{promise[:name]}"
  end
end