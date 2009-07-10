#!/usr/bin/env ruby
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

gem 'ramaze', '=2009.06.12'
require 'ramaze'

# This is an ugly hack to get things working under Jetty/Tomcat.
# It works around a bug in jruby
# I got the workaround from http://markmail.org/message/rn6hmt6nguzopypk?q=%22undefined+method+%60exclusive%27+for+Thread:Class%22
require 'thread'

#
# Configuration Area Start
#

# $connectionString: This sets the connection string to use for your database. 

# First check if we're running under JRuby. If we are, load the JDBC connection string from a file
begin
    include Java
    import java.lang.System
    home = System.getProperty("user.home")

    require 'yaml'
    cfg = YAML.load_file(home + "/.escape/config")
    $connectionString = cfg["jdbc.url"]
rescue
    # We're not in JRuby
    # 
    # SQLite
    $connectionString = "sqlite:///#{File.expand_path(File.dirname(__FILE__))}/escape.db"
    # MySQL
    #$connectionString = "mysql://escape:escape@localhost/escape"
    # Postgres
    #$connectionString = "postgres://escape:escape@localhost/escape"
    # Oracle
    #$connectionString = "oracle://escape:escape@localhost/escape"
    # MySQL over JDBC for JRuby
    #$connectionString = "jdbc:mysql://localhost/escape?user=escape&password=escape"

end

# $listenPort: The TCP port we need to listen on to service requests
#
$listenPort = 7000

# $accessLog: Path to the file where we need to log access to
#
#$accessLog = "access.log"

#
# Configuration Area End
#

# Add directory start.rb is in to the load path, so you can run the app from
# any other working path
$LOAD_PATH.unshift(__DIR__)

EscapeVersion = 0.3

# Initialize controllers and models
require 'model/init'
require 'controller/init'

#log = Logger.new($accessLog)
#Rack::CommonLogger.new(Ramaze::Log, log)

#Ramaze.start :adapter => :mongrel, :port => $listenPort

