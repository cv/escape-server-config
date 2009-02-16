
require 'rake/clean'
require 'rake/packagetask'
require 'rexml/document'

CLEAN.include('escape.db')
CLEAN.include('dist')

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

desc 'Create release package'
task :release => [:clean] do
    sh "bash release.sh"
end
