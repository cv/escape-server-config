#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
require 'json'
require 'openssl'
require 'time'

class EnvironmentsController < EscController
  map '/environments'

  def index(env = nil, app = nil, key = nil)
    # Sanity check what we've got first
    if env && (not env =~ /\A[.a-zA-Z0-9_-]+\Z/)
      respond "Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403
    end

    if app && (not app =~ /\A[.a-zA-Z0-9_-]+\Z/)
      respond "Invalid application name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403
    end

    if key && (not key =~ /\A[.a-zA-Z0-9_-]+\Z/)
      respond "Invalid key name. Valid characters are ., a-z, A-Z, 0-9, _ and -", 403
    end

    @env = env
    @app = app
    @key = key

    # Getting...
    if request.get?
      # List all environments
      if env.nil?
        list_envs
        # List all apps in specified environment
      elsif app.nil?
        list_apps
        # List keys and values for app in environment
      elsif key.nil?
        list_keys
        # We're getting value for specific key
      else
        get_value
      end

      # Copying...
    elsif request.post?
      # Undefined
      if env.nil?
        respond "Undefined", 400
        # You're copying an env
      elsif app.nil?
        # env is the target, Location Header has the source
        copy_env
      end

      # Creating...
    elsif request.put?
      # Undefined
      if env.nil?
        response.status = 400
        # You're creating a new env
      elsif app.nil?
        create_env
        # You're creating a new app
      elsif key.nil?
        create_app
        # Key stuff
      else
        set_value
      end

      # Deleting...
    elsif request.delete?
      # Undefined
      if env.nil?
        response.status = 400
        # You're deleting an env
      elsif app.nil?
        delete_env
        # You're deleting an app
      elsif key.nil?
        delete_app
        # You're deleting a key
      else
        delete_key
      end
    end
  end

  private

  #
  # Deletion
  #

  def delete_env
    respond "Not allowed to delete default environment!", 403 if @env == "default"
    get_env
    check_env_auth
    @my_env.delete
    respond "Environment '#{@env}' deleted.", 200
  end

  def delete_app
    get_app

    if @env == "default"
      if @my_app.environments.size == 1
        @my_app.delete
        respond "Applicaton '#{@app}' deleted.", 200
      else
        respond "Applicaton '#{@app}' is used in other environments.", 412
      end
    else
      get_env
      check_env_auth
      @my_app.remove_environment @my_env
      respond "Application '#{@app}' deleted from the '#{@env}' environment.", 200
    end
  end

  def delete_key
    get_env
    get_app
    get_key

    if @env == "default"
      # Don't delete default if we have a value set in a non-default env
      set = false
      @my_key.app.environments.each do |appenv|
        if (not Value[:key_id => @keyId, :environment_id => appenv[:id]].nil?) and (appenv.name != "default")
          set = true
          break
        end
      end

      if not set
        @my_key.delete
        respond "Key '#{@key}' deleted from application '#{@app}'.", 200
      else
        respond "Key #{@key} can't be deleted. It has non default values set.", 403
      end
    else
      check_env_auth
      my_value = Value[:key_id => @keyId, :environment_id => @env_id]
      if my_value.nil?
        respond "Key '#{@key}' has no value in the '#{@env}' environment.", 404
      else
        my_value.delete
        respond "Key '#{@key}' deleted from the '#{@env}' environment.", 200
      end
    end

  end

  #
  # Getters
  #

  def check_last_modified(modified)
    return false unless request.env['HTTP_IF_MODIFIED_SINCE']

    if modified <= Time.parse(request.env['HTTP_IF_MODIFIED_SINCE'])
      response.status = 304
      return true
    end

    return false
  end

  def list_envs
    envs = []
    Environment.all.each do |env|
      envs.push(env[:name])
    end
    response.headers["Content-Type"] = "application/json"
    return envs.sort.to_json
  end

  def list_apps
    # List all apps in specified environment
    get_env

    apps = []
    @my_env.apps.each do |app|
      apps.push app[:name]
    end

    response.headers["Content-Type"] = "application/json"
    return apps.sort.to_json
  end

  def list_keys
    # List keys and values for app in environment
    get_env
    get_app

    if @my_env.apps.include? @my_app
      pairs = []
      defaults = []
      overrides = []
      encrypted = []
      modified = []
      @my_app.keys.each do |key|
        value = Value[:key_id => key[:id], :environment_id => @env_id]

        if value.nil? # Got no value in specified env, what's in default and do we want defaults?
          value = Value[:key_id => key[:id], :environment_id => @default_id]
          defaults.push key[:name]
        else
          overrides.push key[:name]
        end

        encrypted.push key[:name] if value[:is_encrypted]
        pairs.push "#{key[:name]}=#{value[:value].gsub("\n", "")}\n"
        modified.push value[:modified]
      end

      #return nil if check_last_modified(modified.max)

      response.headers["Content-Type"] = "text/plain"
      response.headers["X-Default-Values"] = defaults.sort.to_json
      response.headers["X-Override-Values"] = overrides.sort.to_json
      response.headers["X-Encrypted"] = encrypted.sort.to_json
      response.headers["Last-Modified"] = modified.max.httpdate unless modified.empty?

      return pairs.sort
    else
      respond "Application '#{@app}' is not included in Environment '#{@env}'.", 404
    end
  end

  def get_value
    get_env
    get_app

    if not @my_env.apps.include? @my_app
      respond "Application '#{@app}' is not included in Environment '#{@env}'.", 404
    end

    get_key false

    value = @my_app.get_key_value(@my_key, @my_env)
    if value.nil?
      respond "No default value", 404
    else
      if value.default?
        response.headers["X-Value-Type"] = "default"
      else
        response.headers["X-Value-Type"] = "override"
      end
    end

    #check_last_modified(value[:modified])

    if value[:is_encrypted]
      response.headers["Content-Type"] = "application/octet-stream"
      response.headers["Content-Transfer-Encoding"] = "base64"
    else
      response.headers["Content-Type"] = "text/plain"
    end

    response.headers["Last-Modified"] = value[:modified].httpdate
    return value[:value]
  end

  #
  # Creaters
  #

  def create_env
    respond "Environment '#{@env}' already exists.", 200 if Environment[:name => @env]

    @my_env = Environment.create :name => @env
    @pair = "pair"
    create_crypto_keys
    respond "Environment created.", 201
  end

  def create_app
    get_env
    check_env_auth
    get_app false
    respond "Application '#{@app}' already exists in environment '#{@env}'.", 200 if @my_app and @my_app.environments.include? @my_env

    if @my_app.nil?
      @my_app = App.create :name => @app
    end
    @my_env.add_app @my_app unless @my_env.apps.include? @my_app

    respond "Application '#{@app}' created in environment '#{@env}'.", 201
  end

  def set_value
    get_env
    check_env_auth
    get_app

    value = request.body.read
    encrypted = if request.env['QUERY_STRING'] =~ /encrypt/
      respond "Can't encrypt data in the default environment", 412 if @env == "default"
      # Do some encryption
      public_key = OpenSSL::PKey::RSA.new @my_env.public_key
      encrypted_value = Base64.encode64(public_key.public_encrypt(value)).strip
      value = encrypted_value
      true
    else
      false
    end

    if @my_app.set_key_value @key, @my_env, value, encrypted
      respond "Created key '#{@key}", 201
    else
      respond "Updated key '#{@key}", 200
    end
  end

  def copy_env
    respond "Missing Content-Location header. Can't copy environment", 406 unless request.env['HTTP_CONTENT_LOCATION']

    src_env = Environment[:name => request.env['HTTP_CONTENT_LOCATION']]
    respond "Source environment '#{request.env['HTTP_CONTENT_LOCATION']}' does not exist.", 404 if src_env.nil?

    get_env false
    respond "Target environment #{@env} already exists.", 409 unless @my_env.nil?

    # Create new env
    @my_env = Environment.create(:name => @env)
    @pair = "pair"
    create_crypto_keys

    src_env_id = src_env[:id]
    dest_env_id = @my_env[:id]
    # Copy applications into new env
    src_env.apps.each do |existing_app|
      @my_env.add_app(existing_app)
      # Copy overridden values
      existing_app.keys.each do |key|
        value = Value[:key_id => key[:id], :environment_id => src_env_id]
        Value.create(:key_id => key[:id], :environment_id => dest_env_id, :value => value[:value], :is_encrypted => value[:is_encrypted]) unless value.nil?
      end
    end
  end
end

