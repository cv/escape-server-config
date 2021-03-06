#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
require 'openssl'
require 'base64'
require 'digest/md5'

class EscController < Ramaze::Controller
  private

  # Get instance info
  def get_env(fail_on_error = true)
    @my_env = Environment[:name => @env]
    respond("Environment '#{@env}' does not exist.", 404) if @my_env.nil? and fail_on_error

    @env_id = @my_env[:id] unless @my_env.nil?
    @default_id = Environment[:name => "default"][:id]
  end

  def get_app(fail_on_error = true)
    @my_app = App[:name => @app]
    respond("Application '#{@app}' does not exist.", 404) if @my_app.nil? and fail_on_error

    @app_id = @my_app[:id] unless @my_app.nil?
  end

  def get_key(fail_on_error = true)
    @my_key = Key[:name => @key, :app_id => @app_id]
    respond("There is no key '#{@key}' for Application '#{@app}' in Environment '#{@env}'.", 404) if @my_key.nil? and fail_on_error

    @keyId = @my_key[:id] unless @my_key.nil?
  end

  # Create a keypair
  def create_crypto_keys
    if @env == "default"
      respond("Default environment doesn't have encryption", 401)
    end

    key = OpenSSL::PKey::RSA.generate(512)
    private_key = key.to_pem
    public_key = key.public_key.to_pem
    @my_env.update(:private_key => private_key, :public_key => public_key)

    response.status = 201
    response.headers["Content-Type"] = "text/plain"
    return public_key + "\n" + private_key
  end

  def check_auth(id = nil, realm = "")
    return id if id == "nobody"

    response['WWW-Authenticate'] = "Basic realm=\"ESCAPE Server - #{realm}\""

    if auth = request.env['HTTP_AUTHORIZATION']
      (user, pass) = Base64.decode64(auth.split(" ")[1]).split(':')
      id = user if id.nil?
      owner = Owner[:name => user]
      if owner && (owner.password == Digest::MD5.hexdigest(pass)) && (id == user)
        return user
      end
    end

    respond 'Unauthorized', 401
  end

  def get_env_auth
    check_auth nil, "Environment #{@env}"
  end

  def check_env_auth
    check_auth @my_env.owner.name, "Environment #{@env}"
  end

  def check_user_auth
    check_auth @name, "User #{@name}"
  end
end

# Here go your requires for subclasses of Controller:
%w[main environments crypt owner user auth search].each { |f| require_relative f }
