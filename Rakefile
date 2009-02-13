
require 'rake/clean'
require 'rexml/document'

releaseDir = 'release'

CLEAN.include('escape.db')
CLEAN.include(releaseDir)

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
    mkdir releaseDir
    sh "svn info --xml" do |ok, res|
        if ok
            xmlData = res
        end
    end
end
