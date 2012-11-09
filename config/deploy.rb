require "bundler/vlad"

set :user, "tuupola"
set :application, "sinatra-dm-facebook" 

set :repository, "git@github.com:#{user}/#{application}.git"
set :user, "sinatra"
set :server, "#{application}.taevas.com"
set :domain, "#{user}@#{server}"
set :deploy_to, "/srv/www/#{server}"
set :remote_port, 4567
set :local_port, 9393

require "vlad"

namespace :vlad do
  desc "Start remote node.js server"
  remote_task :start_node, :roles => :app do
    run "cd #{current_release} && forever start app.js"
  end

  desc "Stop remote node.js server"
  remote_task :stop_node, :roles => :app do
    run "cd #{current_release} && forever stop app.js"
  end
  
  remote_task :start_stalker do
    puts "Starting Stalker worker"
    # Start from newly deployed release
    run "cd #{release_path} && bin/worker.rb start"
  end

  remote_task :stop_stalker do
    puts "Stopping Stalker worker"
    # Stop from previously deployed release
    run "cd #{current_release} && bin/worker.rb stop"
  end
  
  desc "Deploy the code and restart the server"
  #task :deploy => [:stop_stalker, :update, :"bundle:install", :start_app, :start_stalker]  
  #task :deploy => [:stop_node, :update, :"bundle:install", :start_app, :start_node]  
  task :deploy => [:update, :"bundle:install", :start_app]  
end

namespace :dev do
  task :start_shotgun do
    system "bundle exec shotgun --port=#{local_port} config.ru"
  end

  desc "Start ssh tunnel between #{server}:#{remote_port} and localhost:#{local_port}"
  task :start_tunnel do
    puts "Tunneling  #{server}:#{remote_port} to localhost:#{local_port}"
    system "autossh -M 48485 -nNT -g -R *:#{remote_port}:127.0.0.1:#{local_port} #{server}"
  end

  remote_task :symlink do
    puts "Symlinking current/public/htaccess to current/public/.htaccess"
    run "ln -f -s #{current_release}/public/htaccess #{current_release}/public/.htaccess"
  end

  desc "Switch to tunneled development mode."
  multitask :start => [ "dev:symlink", "dev:start_shotgun", "dev:start_tunnel" ]
end