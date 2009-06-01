
class AuthController < EscController
    map('/auth')

  def index
    'Public Info'
  end

  def secret
    checkAuth
    'Secret Info'
  end

end

