require "rubygems"
require "bundler/setup"
require "stalker"
require "pp"

#pwd   = File.dirname(__FILE__)
#require File.join(pwd, "../models.rb")

job "example.job" do |args|

  pp "Do something which takes long time..."
  
end