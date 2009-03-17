#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'
require 'base64'

require __DIR__('helper/db_helper')
require __DIR__('../start')

describe AuthController do
    behaves_like 'http', 'db_helper'

    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    before do
        reset_db
    end

    it 'should return a 400 on GET /owner' do
        got = get('/owner')
        got.status.should == 400
    end

    it 'should get the owner of an environment on GET /owner/environment' do
        got = get('/owner/default')
        got.status.should == 200
        got.body.should == "nobody"
        got.content_type.should == "text/plain"
    end

end
