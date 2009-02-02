
require 'rake/clean'

CLEAN.include('escape.db')

task :default => [:test]

desc 'Run all the spec tests'
task :test => [:clean] do
    FileList.new('spec/*.rb').each do |file|
        ruby file
    end
end

desc 'Start up the server'
task :run do
    ruby 'start.ru'
end
