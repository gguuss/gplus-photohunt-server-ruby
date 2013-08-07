# Provides an API for retrieving the currently logged in user. This controller
# provides the /api/users end-point, and exposes the following operations:
#
#   GET /api/users
#
# Author:: samstern@google.com (Sam Stern)
#
class UsersController < ApplicationController

  # Throw 401 User Unauthorized error if a non-authorized request is made.
  before_action :deny_access, unless: :authorized?

  # Exposed as `GET /api/users`.
  #
  # Returns the following JSON response representing the currently logged in
  # User.
  #
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
  # 401: "Unauthorized request".  No user was connected.
  def index
    current_user = User.find(session[:user_id])

    render json: json_encode(user, User.json_only)
  end

end
