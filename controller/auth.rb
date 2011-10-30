#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

class AuthController < EscController
    map('/auth')

  def index
    'Public Info'
  end

  def secret
    check_auth
    'Secret Info'
  end

end

