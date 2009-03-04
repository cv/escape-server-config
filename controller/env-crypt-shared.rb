def createCryptoKeys(env, pair)
    # Create a keypair
    if env == "default"
        response.status = 401
        return "Default environment doesn't have encryption"
    end
    myenv = Environment[:name => env]
    if myenv.nil?
        response.status = 404
        return "Environment '#{env}' does not exist."
    elsif pair == "pair"
        key = OpenSSL::PKey::RSA.generate(1024)
        public_key = key.public_key.to_pem
        private_key = key.to_pem 
        myenv.update(:public_key => public_key, :private_key => private_key)
        response.status = 201
        response.headers["Content-Type"] = "text/plain" 
        return public_key + "\n" + private_key
    else
        response.status = 403
        return "Can only create keys in pairs"
    end
end