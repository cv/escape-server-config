#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'

spec_require 'sequel'

$LOAD_PATH.unshift base = __DIR__('..')
require 'escape'

describe 'Escape' do
    behaves_like 'http'
    ramaze

    it 'should say hello world' do
        page = get("/")
        page.status.should == 200
        page.body.should.not == nil
    end
end


