#   Copyright 2009 ThoughtWorks
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'openssl'

class CryptController < Controller
    map('/crypt')

    def index(env = nil, puborpriv = nil)
        # Sanity check what we've got first
        if env && (not env =~ /\A[.a-zA-Z0-9_-]+\Z/)
            response.status = 403
            return "Invalid environment name. Valid characters are ., a-z, A-Z, 0-9, _ and -"
        end

        if puborpriv && puborpriv != "public" && puborpriv != "private"
            response.status = 403
            return "Must define keytype as either public or private"
        end

        # Getting...
        if request.get?
            # Undefined
            if env.nil?
                response.status = 400
            # Show both keys in specified environment
            elsif puborpriv.nil?
                showCryptoKeys(env, "pair")
            # Show public or private key for environment
            else 
                showCryptoKeys(env, puborpriv)
            end

        # Creating...
        elsif request.put?
            # Undefined
            if env.nil?
                response.status = 400
            # You're creating a new keypair
            elsif puborpriv.nil?
               # createCryptoKeys(env,"pair")
               response.status = 403
               return "Can't create keypars through the API. This is done when an environment is created."
            # You're doing something silly
            else             
                response.status = 403
            end
            
        # Updating...
        elsif request.post?
            # Undefined
            if env.nil?
                response.status = 400
            # You're updating a keypair
            elsif puborpriv.nil?
                keys = request.body.read
                updateCryptoKeys(env, "pair", keys)
            # You're trying to update a single key. Naughty!
            else 
                response.status = 403
            end       

        # Deleting...
        elsif request.delete?
            # Undefined
            if env.nil?
                response.status = 404
            # You're deleting a keypair
            elsif puborpriv.nil?
                deleteCryptoKeys(env,"pair")
            # You're deleting a crypto key
            else                         
                deleteCryptoKeys(env, puborpriv)
            end
        end
    end

    private
    
    def showCryptoKeys(env, pair)
        # Show keys in an environment
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        else
            response.status = 200
            response.headers["Content-Type"] = "text/plain"   
            if pair == "pair"
                return "#{myenv.public_key}" + "\n" +  "#{myenv.private_key}"
            elsif pair == "private"
                return "#{myenv.private_key}"
            elsif pair == "public"
                return "#{myenv.public_key}"
            else
                response.status = 403
                return "Crypto keys can only be public or private or in a pair"
            end
        end
    end
    
    def deleteCryptoKeys(env, pair)
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        elsif env == "default"
            response.status = 403
            return "Can't delete keys from default environment."
        else
            response.status = 200
            if pair == "pair"
                myenv.update(:public_key => '', :private_key => '')
                return               
            elsif pair == "private"
                myenv.update(:private_key => nil)
                return
            elsif pair == "public"
                myenv.update(:public_key => nil)
                return
            else
                response.status = 403
                return "Crypto keys can only be public or private or in a pair"
            end
        end
    end
    
    def updateCryptoKeys(env, pair, keys)
        myenv = Environment[:name => env]
        if myenv.nil?
            response.status = 404
            return "Environment '#{env}' does not exist."
        elsif env == "default"
            response.status = 403
            return "Can't put keys into default environment."
        elsif pair != "pair"
            response.status = 403
            return "Only update keys in a pair"
        else
            if keys && keys != ''
                # Updating with provided values
                /(-----BEGIN RSA PUBLIC KEY-----.*-----END RSA PUBLIC KEY-----)/m.match(keys)
                public_key = $1
                /(-----BEGIN RSA PRIVATE KEY-----.*-----END RSA PRIVATE KEY-----)/m.match(keys)
                private_key = $1
                if public_key && private_key
                    myenv.update(:public_key => public_key, :private_key => private_key)
                    response.status = 201
                    return 
                else
                    response.status = 501
                end
            else
                # Creating new keys
                createCryptoKeys(env, pair)
                response.status = 201
                return               
            end                    
        end
    end
    
end
