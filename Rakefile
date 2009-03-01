
require 'rake/clean'
require 'rake/packagetask'
require 'rexml/document'

require 'selenium/rake/tasks'


CLEAN.include('escape.db')
CLEAN.include('dist')

task :default => [:test]

desc 'Run all the spec tests'
task :test => [:clean] do
    FileList.new('spec/*.rb').each do |file|
        ruby file
    end
end

desc 'Run the selenium tests'
task :selenium do
    FileList.new('selenium/*.rb').each do |file|
        ruby(file + " --color --require 'rubygems,selenium/rspec/reporting/selenium_test_report_formatter' --format=Selenium::RSpec::SeleniumTestReportFormatter:./reports/acceptance_tests_report.html --format=progress")
    end
end

desc 'Start up the server'
task :run do
    ruby 'start.ru'
end

desc 'Create release package'
task :release => [:clean] do
    sh "bash release.sh"
end
