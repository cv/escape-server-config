#!/usr/bin/env ruby

require 'ramaze'
require 'ramaze/spec/helper'

require __DIR__('../start')

describe ConfigController do
    behaves_like 'http', 'xpath'
    ramaze  :view_root => __DIR__('../view'),
            :public_root => __DIR__('../public')

    it 'should list applications on GET /config' do
        got = get('/config')
        got.status.should == 200
        got.body.should == ""
    end

    it 'should put /config' do
        got = put('/config')
        got.status.should == 200
        got.body.should == "put me"
    end

    it 'should post /config' do
        got = post('/config')
        got.status.should == 200
        got.body.should == "post me"
    end
end
