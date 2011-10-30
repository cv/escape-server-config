#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'

describe MainController do
    behaves_like :rack_test, :db_helper

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

