#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#   Copyright 2009 ThoughtWorks
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'rubygems'
require 'ramaze'

require 'yaml'
require 'etc'

#
# Configuration Area Start
#
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

    File.new("#{home}/.escape/config", 'w') do |f|
      f.write(YAML.dump(cfg))
    end
end

$connection_string = cfg["database"]
$listen_port = cfg["port"]

#
# Configuration Area End
#

# Add directory start.rb is in to the load path, so you can run the app from
# any other working path
$LOAD_PATH.unshift(__DIR__)

EscapeVersion = 0.4

# Initialize controllers and models
require 'model/init'
require 'controller/init'

#log = Logger.new($accessLog)
#Rack::CommonLogger.new(Ramaze::Log, log)

#Ramaze.start :adapter => :mongrel, :port => $listen_port

