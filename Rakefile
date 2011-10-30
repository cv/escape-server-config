# -*- encoding : utf-8 -*-
require 'rubygems'
require 'bundler/setup'

require 'rake/clean'
require 'rake/packagetask'
require 'timeout'
require 'socket'

CLEAN << %w{escape.db reports tmp}

task :default => [:test]

desc 'Run all the spec tests'
task :test => [:clean] do
  sh 'bacon', *Dir['spec/**/*.rb']
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
