# Provides an API for working with Votes.  This controller provides the
# /api/votes end-point, and exposes the following operations:
#
#   PUT /api/votes
#
# Author:: samstern@google.com (Sam Stern)
#
class VotesController < ApplicationController

  # Throw 401 User Unauthorized error if a non-authorized request is made.
  before_action :deny_access, unless: :authorized?

  # Allow JSON POST requests to the create endpoint, without requiring the
  # Rails CSRF token.
  skip_before_filter :verify_authenticity_token, only: [ :create ]

  # Exposed as `PUT /api/votes`.
  #
  # Takes a request payload that is a JSON object containing the Photo ID
  # for which the currently logged in user is voting.
  #
  # {
  #   "photoId":0
  # }
  #
  # Returns the following JSON response representing the Photo for which the
  # User voted.
  #
  # {
  #   "id":0,
  #   "ownerUserId":0,
  #   "ownerDisplayName":"",
  #   "ownerProfileUrl":"",
  #   "ownerProfilePhoto":"",
  #   "themeId":0,
  #   "themeDisplayName":"",
  #   "numVotes":1,
  #   "voted":true,
  #   "created":0,
  #   "fullsizeUrl":"",
  #   "thumbnailUrl":"",
  #   "voteCtaUrl":"",
  #   "photoContentUrl":""
  # }
  #
  # Issues the following errors along with corresponding HTTP response codes:
  # 401: "Unauthorized request".  No user was connected to vote.
  # 500: "Error writing app activity: " + error from client library
  def create
    vote = Vote.where(
      photo_id: params[:photoId],
      owner_user_id: session[:user_id]).first_or_initialize

    photo = Photo.find(params[:photoId])
    photo.voted = true

    if (vote.id.nil?)
      # Vote is new, post an App Activity
      token_data = TokenData.from_user(User.find(session[:user_id]))
      Rails.logger.info(token_data.inspect)
      gapi_client = get_gapi_client(token_data)
      # TODO(samstern): Check for token expiring soon.
      vote.post_moment!(gapi_client)
    end
    vote.save!

    render json: json_encode(photo, Photo.json_only)
  end

end
