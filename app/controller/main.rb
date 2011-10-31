#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

class MainController < EscController
  layout '/index'
  helper :xhtml

  def index
    @title = "Esc Serves Config"
  end

end
