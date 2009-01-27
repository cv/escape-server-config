#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/helper'

spec_require 'sequel'

$LOAD_PATH.unshift base = __DIR__('..')
require 'escape'


describe 'Escape' do
    behaves_like 'http'
    ramaze  :public_root => base/:public,
            :view_root   => base/:view


    


end


