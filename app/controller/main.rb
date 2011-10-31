#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

class MainController < EscController
  layout 'index'
  helper :xhtml
  map '/'

  def index
    @title = "Esc Serves Config"
  end

end
