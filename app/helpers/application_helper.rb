module ApplicationHelper
  require 'jbuilder'
  require 'google/api_client'
  require 'google/api_client/client_secrets'

  # Encode an object as a JSON string.  Extracts all of the properties in
  # `only` and camelizes the JSON key.
  # Params:
  # +obj+:: the object to encode.
  # +only+:: an array of symbols representing methods and attributes to
  #   extract.
  def json_encode(obj, only)
    Jbuilder.encode do |json|
      json.key_format! camelize: :lower
      json.extract! obj, *only
    end
  end

  # Encode an array of objects as a JSON string.  Extracts all of the properties
  # in `only` and camelizes the JSON key.
  # Params:
  # +obj+:: the array of objects to encode.
  # +only+:: an array of symbols representing methods and attributes to
  #   extract.
  def json_encode_array(arr, only)
    Jbuilder.encode do |json|
      json.array! arr do |elm|
        json.key_format! camelize: :lower
        json.extract! elm, *only
      end
    end
  end

  # Returns the base url (protocol, domain, and port) of the request object.
  def get_request_base
    "#{request.protocol}#{request.host}:#{request.port}"
  end

  # Gets a Google API Client object from a TokenData argument.  If the
  # TokenData has a `code`, it will be exchanged for an `access_token`.
  def get_gapi_client(token_data)
    client = Google::APIClient.new
    client.authorization = gapi_authorization(token_data)

    if(token_data.code.nil?)
      if (token_data.access_token.nil?)
        raise Exceptions::PhotoHuntError.new(400, 'Missing access token in request.')
      else
        client.authorization.access_token = token_data.access_token
      end
    end

    return client
  end

  # Read and parse the `client_secrets.json` file and load it into an object.
  def read_client_secrets
    file_path = Rails.root.join('config', 'client_secrets.json')
    Google::APIClient::ClientSecrets.load(file_path)
  end

  # Create a Signet::OAuth2::Client from a TokenData object.  Serves as
  # authorization for a Google API Client Object. If the TokenData has a
  # `code`, it will be exchanged for an `access_token`.
  def gapi_authorization(token_data)
    # Read in the client secrets
    client_secrets = read_client_secrets

    authorization = Signet::OAuth2::Client.new(
      authorization_uri: client_secrets.authorization_uri,
      token_credential_uri: client_secrets.token_credential_uri,
      client_id: client_secrets.client_id,
      client_secret: client_secrets.client_secret,
      scope: 'https://www.googleapis.com/auth/plus.login')

    if (!token_data.code.nil?)
      authorization.redirect_uri = client_secrets.redirect_uris.first
      authorization.code = token_data.code
      authorization.fetch_access_token!
    end

    return authorization
  end

  # Verify an access_token with Google, confirm that it is issued for the
  # correct application and that it is valid.
  def verify_token(access_token)

    token_info = nil
    begin
      base = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token="
      url = URI.parse("#{base}#{access_token}")

      token_info = JSON.parse(get_request(url).body)
    rescue => e
      raise Exceptions::PhotoHuntError(500,
        'Failed to read token data from Google')
    end

    # Check for error in response
    if !token_info['error'].nil?
      raise Exceptions::PhotoHuntError(401, token_info['error'])
    end

    # Read in the client secrets
    client_secrets = read_client_secrets

    # Check that both the local client_id and the returned client_id match
    # this regex.  Then check that they have the same prefix.
    id_regex = /^(\d*)(.*).apps.googleusercontent.com$/
    local_match = client_secrets.client_id =~ id_regex
    remote_match = token_info['issued_to'] =~ id_regex

    local_group = client_secrets.client_id.scan(id_regex)[0][0]
    remote_group = token_info['issued_to'].scan(id_regex)[0][0]

    if (!local_match || !remote_match || !(local_group.eql?(remote_group)))
      raise Exceptions::PhotoHuntError(401,
        "Token's client ID does not match app's.")
    end

    return token_info
  end

  # Revoke an `access_token`.  Called when a user disconnects.
  def revoke_token(access_token)
    begin
      base = "https://accounts.google.com/o/oauth2/revoke?token="
      url = URI.parse("#{base}#{access_token}")

      response = get_request(url)
    rescue => e
      raise Exceptions::PhotoHuntError(500,
        'Failed to revoke token for given user')
    end
  end

  # Makes a get request over HTTPs to a given URI object.  Returns the
  # server response.
  def get_request(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Get.new(url.request_uri)
    response = http.request(request)

    return response
  end

end
