#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Dir["app/tasks/**/*.{rake,rb}"].each do |file|
  load file
end

MyMusicDatabase::Application.load_tasks
