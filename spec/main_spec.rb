#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
require 'spec_helper'

describe MainController do

  it 'should show start page' do
    got = get '/'
    got.status.should == 200
    got.body.should_not == ''
    got.body.should include 'ESCAPE'
  end

  it 'should have /environments wired in' do
    got = get '/environments'
    got.status.should == 200
  end

end

