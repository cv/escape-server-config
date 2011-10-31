#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

# This controller handles the specific owner of each given environment
class SearchController < EscController
  map '/search'

  def index(text = nil)
    respond("Usage: GET /search/text", 400) if text.nil? || !request.get?
    envs = []
    Environment.where('name like ?', '%' + text + '%').each do |env|
      envs.push(env[:name])
    end
    response.headers["Content-Type"] = "application/json"
    return envs.sort.to_json
  end
end
