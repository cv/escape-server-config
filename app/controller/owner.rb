#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

# This controller handles the specific owner of each given environment
class OwnerController < EscController
  map '/owner'

  def index(env = nil)
    # Sanity check what we've got first
    if env && (not env =~ /\A[.a-zA-Z0-9_-]+\Z/)
      respond("Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403)
    end

    # Undefined
    if env.nil?
      respond("Undefined", 400)
    end

    @env = env

    # Getting...
    if request.get?
      get_owner
    elsif request.post?
      set_owner
    elsif request.delete?
      clear_owner
    else
      respond("Undefined", 400)
    end
  end

  private

  def get_owner
    get_env

    owner = Owner[:id => @my_env.owner_id]

    response.headers["Content-Type"] = "text/plain"
    return owner.name
  end

  def set_owner
    if @env == "default"
      respond("No one can own the 'default' environment", 403)
    end

    get_env

    if @my_env.owner_id == 1
      #auth = check_auth(nil, "Environment #{@env}")
      auth = get_env_auth
    else
      auth = check_env_auth
    end

    owner = Owner[:name => auth]

    respond("Owner #{auth} not found", 404) if owner.nil?

    @my_env.owner = owner
    @my_env.save
    return "Owner of environment #{@env} is now #{auth}"
  end

  def clear_owner
    get_env

    if @my_env.owner_id == 1
      respond("Environment #{@env} is not owned by anyone", 200)
    else
      auth = check_env_auth
    end

    @my_env.owner = Owner[:name => "nobody"]
    @my_env.save
    return "Owner of environment #{@env} is now nobody"
  end

end
