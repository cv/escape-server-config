
require 'rubygems'
require 'rake/clean'
require 'rake/packagetask'
require 'rexml/document'
require 'timeout'
require 'socket'

#require "selenium/client" 
#require 'selenium/rake/tasks'

#Selenium::Rake::RemoteControlStartTask.new("rc_start") do |rc|
#    rc.port = 4444
#    rc.timeout_in_seconds = 3 * 60
#    rc.background = false
#    rc.wait_until_up_and_running = true
#    rc.jar_file = "selenium/selenium-server.jar"
#    rc.additional_args << "-singleWindow"
#end 

#Selenium::Rake::RemoteControlStopTask.new("rc_stop") do |rc|
#    rc.host = "localhost"
#    rc.port = 4444
#    rc.timeout_in_seconds = 3 * 60
#end 

CLEAN.include('escape.db')
CLEAN.include('dist')
CLEAN.include('reports')
CLEAN.include('*.war')
CLEAN.include('tmp')

task :default => [:test]

desc 'Run all the spec tests'
task :test => [:clean] do
    FileList.new('spec/*.rb','spec/model/*.rb').each do |file|
        ruby file
    end
end

desc 'Run the selenium tests'
task :selenium_tests do
    # Wait for a minute for ports 4444 and 7000 to come up, then run tests
    [4444, 7000].each do |port| 
        status = Timeout::timeout(15) {
            while true do
                begin
                    sock = TCPSocket.open("localhost", port)
                rescue
                    sleep(1)
                else
                    break
                end
            end
        }
    end
    FileList.new('selenium/*.rb').each do |file|
        ruby(file + " --color --require 'rubygems,selenium/rspec/reporting/selenium_test_report_formatter' --format=Selenium::RSpec::SeleniumTestReportFormatter:./reports/acceptance_tests_report.html --format=progress")
    end
end

desc 'Start up the server'
task :run do
    ruby 'start.rb'
end

desc 'Create release package'
task :release => [:clean] do
    sh "bash release.sh"
end

desc "Start up Selenium Server and Escape Server, then run the selenium tests..."
task :selenium do
    # TODO: Startup server and rc if they're not there. Call the tests, then stop
end



