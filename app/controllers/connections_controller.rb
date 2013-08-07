# Provides an API to connect and disconnect users to/from Photohunt.
# This controller provides the /api/connect and /api/disconnect end-points,
# and exposes the following operations:
#
#   POST /api/connect
#   POST /api/disconnect
#
# @author samstern@google.com (Sam Stern)
#
class ConnectionsController < ApplicationController
  include PlusUtils
  require 'google/api_client'
  require 'google/api_client/client_secrets'

  # Throw 401 User Unauthorized error if a non-authorized request to the
  # disconnect endpoint is made.
  before_action :deny_access, unless: :authorized?, only: [:destroy]

  # Allow JSON POST requests to the connect and disconnect endpoints, without
  # requiring the Rails CSRF token.
  skip_before_filter :verify_authenticity_token, only: [ :create, :destroy ]

  # Exposed as `POST /api/connect`.
  #
  # Takes the following payload in the request body.  The payload represents
  # all of the parameters that are required to authorize and connect the user
  # to the app.
  # {
  #   "state":"",
  #   "access_token":"",
  #   "token_type":"",
  #   "expires_in":"",
  #   "code":"",
  #   "id_token":"",
  #   "authuser":"",
  #   "session_state":"",
  #   "prompt":"",
  #   "client_id":"",
  #   "scope":"",
  #   "g_user_cookie_policy":"",
  #   "cookie_policy":"",
  #   "issued_at":"",
  #   "expires_at":"",
  #   "g-oauth-window":""
  # }
  #
  # Returns the following JSON response representing the User that was
  # connected:
  # {
  #   "id":0,
  #   "googleUserId":"",
  #   "googleDisplayName":"",
  #   "googlePublicProfileUrl":"",
  #   "googlePublicProfilePhotoUrl":"",
  #   "googleExpiresAt":0
  # }
  #
  # Issues the following errors along with corresponding HTTP response codes:
  # 400: Missing access token in request.
  # 401: The error from the Google token verification end point.
  # 500: "Failed to read token data from Google."
  def create
    # Read the token information
    token_data = TokenData.new(params)

    client = get_gapi_client(token_data)
    plus = get_plus(client)

    # Verify access_token, 401 on failure
    token_info = verify_token(client.authorization.access_token)

    me_result = client.execute(
      api_method: plus.people.get,
      parameters: { userId: 'me' })
    user_info = me_result.data

    # TODO(samstern): Also fetch and set the email
    user = User.where(google_user_id: user_info['id']).first
    if user.nil?
      user = User.from_json(user_info)
    end

    user.google_access_token = client.authorization.access_token
    unless client.authorization.refresh_token.nil?
      user.google_refresh_token = client.authorization.refresh_token
    end
    user.google_expires_in = token_info['expires_in'].to_i
    user.google_expires_at = (DateTime.now().to_i + user.google_expires_in) * 1000
    user.save!

    # Save current user id in the session
    session[:user_id] = user.id

    # Asynchronously load all of the user's friends
    background do
      people_ids = User.gplus_friend_ids(client, nil)
      friends = User.where(google_user_id: people_ids)

      friends.each do |friend|
        # Save the directed edge, if the friend is not nil
        DirectedUserToUserEdge.where(
          owner_user_id: user.id,
          friend_user_id: friend.id
        ).first_or_initialize.save!
      end
    end

    render json: json_encode(user, User.json_only)
  end

  # Exposed as `POST /api/disconnect`.
  #
  # As required by the Google+ Platform Terms of Service, this end-point:
  #
  #   1. Deletes all data retrieved from Google that is stored in our app.
  #   2. Revokes all of the user's tokens issued to this app.
  #
  # Takes no request payload, and disconnects the user currently identified
  # by their session.
  #
  # Returns the following JSON response representing the User that was
  # connected:
  #
  #   "Successfully disconnected."
  #
  # Issues the following errors along with corresponding HTTP response codes:
  # 401: "Unauthorized request".  No user was connected to disconnect.
  # 500: "Failed to revoke token for given user"
  def destroy
    current_user = User.find(session[:user_id])

    # Revoke the Google+ access token
    revoke_token(current_user.google_access_token)

    # Will also destroy all of the user's Edges, Votes, and Photos
    current_user.destroy
    session[:user_id] = nil

    render json: "Successfully disconnected"
  end

end
