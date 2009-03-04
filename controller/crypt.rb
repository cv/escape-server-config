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

class CryptController < Ramaze::Controller
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
                listCryptoKeys(env, "pair")
            # Show public or private key for environment
            else 
                listCryptoKeys(env, puborpriv)
            end

        # Creating...
        elsif request.put?
            # Undefined
            if env.nil?
                response.status = 400
            # You're creating a new keypair
            elsif puborpriv.nil?
                createCryptoKeys(env,"pair")
            # You're pushing in a crypto key
            else             
                value = request.body.read
                createCryptoKeys(env, puborpriv, value)
            end

        # Deleting...
        elsif request.delete?
            # Undefined
            if env.nil?
                response.status = 400
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
    
    def listCryptoKeys()
    end
    
    def createCryptoKeys()
    end
    
    def deleteCryptoKeys()
    end

    # Creation
    def generate_keypair()
        key = OpenSSL::PKey::RSA.generate(1024)
        public_key = key.public_key.to_pem
        private_key = key.to_pem
        return public_key, private_key
    end
    
end
