#!/usr/bin/env ruby

$LOAD_PATH.push(File.expand_path(File.dirname(__FILE__)))
require 'init'

describe SearchController do
    behaves_like :rack_test, :db_helper

    before do
        reset_db
    end

    # Environment tests
    it 'should only accept GET on /search' do
        got = put('/search/sheep')
        got.status.should == 400

        got = post('/search/sheep')
        got.status.should == 400

        got = delete('/search/sheep')
        got.status.should == 400

        got = get('/search/sheep')
        got.status.should == 200
    end

    it 'should require a search string' do
        got = get('/search/')
        got.status.should == 400

        got = get('/search/sheep')
        got.status.should == 200
    end

    it 'should return a json list of matching environments' do
        got = get('/search/def')
        got.status.should == 200
        got.body.should == '["default"]'

        got = get('/search/ult')
        got.status.should == 200
        got.body.should == '["default"]'

        got = get('/search/fau')
        got.status.should == 200
        got.body.should == '["default"]'
    end
end

