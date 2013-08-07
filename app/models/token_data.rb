# Simple class to represent token information sent/recieved from or app and its clients.
class TokenData

  attr_accessor :access_token, #Google access token used to authorize requests.
                :refresh_token, # Google refresh token used to get new tokens when needed.
                :code, # Authorization code used to exchange for an access/refresh token pair.
                :id_token, # Identity token for this user.
                :expires_at, # When the access token expires.
                :expires_in # How long until the access token expires.

  def initialize
    # Empty initializer
  end

  # Create a new TokenData object from a parameters hash.
  def initialize(parameters)
    @access_token = parameters[:access_token]
    @refresh_token = parameters[:refresh_token]
    @code = parameters[:code]
    @id_token = parameters[:id_token]
    @expires_in = parameters[:expires_in]
    @expires_at = parameters[:expires_at]
  end

  def self.from_user(user)
    new({
      access_token: user.google_access_token,
      refresh_token: user.google_refresh_token,
      code: nil,
      expires_at: user.google_expires_at,
      expires_in: user.google_expires_in})
  end

end
