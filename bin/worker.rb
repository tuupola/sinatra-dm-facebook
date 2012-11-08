#!/usr/bin/env ruby
require "rubygems"
require "daemons"

pwd  = File.dirname(File.expand_path(__FILE__))
file = pwd + "/jobs.rb"

Daemons.run_proc(
  "example-worker", # name of daemon
  :dir_mode => :normal,
  :dir => File.join(pwd, "../log"),
  :backtrace => true,
  :monitor => true,
  :log_output => true
) do
  exec "stalk #{file}"
end 