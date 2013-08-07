# Provides an API for working with Users. This controller provides
# the /api/friends end-point, and exposes the following operations:
#
#   GET /api/friends
#
# Author:: samstern@google.com (Sam Stern)
#
class FriendsController < ApplicationController

  # Exposed as `GET /api/friends`.
  #
  # Takes no request payload, and identifies the incoming user by the user
  # data stored in their session.
  #
  # Returns the following JSON response representing the people that are
  # connected to the currently signed in user:
  # [
  #   {
  #     "id":0,
  #     "googleUserId":"",
  #     "googleDisplayName":"",
  #     "googlePublicProfileUrl":"",
  #     "googlePublicProfilePhotoUrl":"",
  #     "googleExpiresAt":0
  #   },
  #   ...
  # ]
  #
  # Issues the following errors along with corresponding HTTP response codes:
  # 401: "Unauthorized request"
  def index
    current_user = User.find(session[:user_id])

    render json: json_encode_array(current_user.friends, User.json_only)
  end
end
