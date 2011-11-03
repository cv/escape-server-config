#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
require 'rubygems'
require 'etc'

home = Etc.getpwuid.dir

# Configuration is loaded from ~/.escape/config
# If the file is not there we'll simply create it and make SQLite the db

begin
  cfg = YAML.load_file("#{home}/.escape/config")
rescue
  # File is not there, let's create a default!
  FileUtils.makedirs("#{home}/.escape")
  cfg = {
    "database" => "sqlite:///#{File.expand_path(File.dirname(__FILE__))}/escape.db",
    "port" => 7000
  }

  File.open("#{home}/.escape/config", 'w') do |f|
    f.write(YAML.dump(cfg))
  end
end

$connection_string = cfg["database"]
$listen_port = cfg["port"]

# Initialize controllers and models
require 'app/model/init'
require 'app/controller/init'
