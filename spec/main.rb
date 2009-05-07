#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'

describe MainController do
    behaves_like 'http', 'xpath'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    it 'should show start page' do
        got = get('/')
        got.status.should == 200
        got.body.should.not == ''
        got.body.should.include 'ESCAPE'
    end

    it 'should have /environments wired in' do
        got = get('/environments')
        got.status.should == 200
    end
    
end

