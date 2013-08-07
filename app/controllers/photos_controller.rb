# Provides an API for working with Photos. This controller provides the
# /api/photos endpoint, and exposes the following operations:
#
#   GET /api/photos
#   GET /api/photos?photoId=1234
#   GET /api/photos?themeId=1234
#   GET /api/photos?userId=me
#   GET /api/photos?themeId=1234&userId=me
#   GET /api/photos?themeId=1234&userId=me&friends=true
#   POST /api/photos
#   DELETE /api/photos?photoId=1234
#
# Author:: samstern@google.com (Sam Stern)
#
class PhotosController < ApplicationController

  # Throw 401 User Unauthorized error if a non-authorized request to the
  # photos create or delete endpoint is made.
  before_action :deny_access, unless: :authorized?, only: [ :create, :delete ]

  # Allow JSON POST/DELETE requests to the api/images and create, and delete
  # endpoints, without requiring the Rails CSRF token.
  skip_before_filter :verify_authenticity_token, only: [ :get_url, :create, :delete ]

  # Exposed as `GET /api/photos`.
  #
  # Accepts the following request parameters.
  #
  # 'photoId': id of the requested photo. Will return a single Photo.
  # 'themeId': id of a theme. Will return the collection of photos for the
  #            specified theme.
  # 'userId': id of the owner of the photo. Will return the collection of
  #           photos for that user. The keyword ‘me’ can be used and will be
  #           converted to the logged in user. Requires auth.
  # 'friends': value evaluated to boolean, if true will filter only photos
  #            from friends of the logged in user. Requires auth.
  #
  # Returns the following JSON response representing a list of Photos.
  #
  # [
  #   {
  #     "id":0,
  #     "ownerUserId":0,
  #     "ownerDisplayName":"",
  #     "ownerProfileUrl":"",
  #     "ownerProfilePhoto":"",
  #     "themeId":0,
  #     "themeDisplayName":"",
  #     "numVotes":0,
  #     "voted":false, // Whether or not the current user has voted on this.
  #     "created":0,
  #     "fullsizeUrl":"",
  #     "thumbnailUrl":"",
  #     "voteCtaUrl":"", // URL for Vote interactive post button.
  #     "photoContentUrl":"" // URL for Google crawler to hit to get info.
  #   },
  #   ...
  # ]
  #
  # Issues the following errors along with corresponding HTTP response codes:
  # 401: "Unauthorized request" (if certain parameters are present in the
  #      request)
  def index
    response_obj = []

    if (!params[:photoId].nil?)
      # Get the photo with the given ID and return it
      response_obj = Photo.find(params[:photoId])
      # Set vote status
      response_obj.set_voted_from_user_id(session[:user_id])
    else
      # If the key word 'me' is used, retrieve the current user from the session
      # must be authorized.
      user_id = nil
      if (!params[:userId].nil?)
        if ("me".include?(params[:userId]))
          deny_access unless authorized?
          user_id = session[:user_id]
        else
          user_id = params[:userId]
        end

        if (params[:friends] == "true")
          deny_access unless authorized?
          response_obj = User.find(user_id).friend_photos
        else
          my_photos = User.find(user_id).photos
          response_obj = my_photos
        end
      else
        user_id = session[:user_id]
      end

      theme_id = params[:themeId]
      friends_or_me = (params[:friends] == "true" || params[:userId] == "me")
      if (!theme_id.nil?)
        if (response_obj.empty? && !friends_or_me)
          response_obj = Photo.where(theme_id: theme_id)
        else
          response_obj = response_obj.find_all{ |x| x.theme_id == theme_id.to_i }
        end
      end

      if (response_obj.respond_to?(:each))
        # Set vote status for each Photo
        response_obj.each { |x| x.set_voted_from_user_id(user_id) }
      end
    end

    # Render the photos, different calls depending on if this is a single photo
    # on an array of photos.
    if (response_obj.respond_to?(:each))
      render json: json_encode_array(response_obj, Photo.json_only)
    else
      render json: json_encode(response_obj, Photo.json_only)
    end
  end

  # Exposed as `POST /api/photos`.
  #
  # Takes the following payload in the request body.  Payload represents a
  # Photo that should be created.
  # {
  #   "id":0,
  #   "ownerUserId":0,
  #   "ownerDisplayName":"",
  #   "ownerProfileUrl":"",
  #   "ownerProfilePhoto":"",
  #   "themeId":0,
  #   "themeDisplayName":"",
  #   "numVotes":0,
  #   "voted":false, // Whether or not the current user has voted on this.
  #   "created":0,
  #   "fullsizeUrl":"",
  #   "thumbnailUrl":"",
  #   "voteCtaUrl":"", // URL for Vote interactive post button.
  #   "photoContentUrl":"" // URL for Google crawler to hit to get info.
  # }
  #
  # Returns the following JSON response representing the created Photo.
  # {
  #   "id":0,
  #   "ownerUserId":0,
  #   "ownerDisplayName":"",
  #   "ownerProfileUrl":"",
  #   "ownerProfilePhoto":"",
  #   "themeId":0,
  #   "themeDisplayName":"",
  #   "numVotes":0,
  #   "voted":false, // Whether or not the current user has voted on this.
  #   "created":0,
  #   "fullsizeUrl":"",
  #   "thumbnailUrl":"",
  #   "voteCtaUrl":"", // URL for Vote interactive post button.
  #   "photoContentUrl":"" // URL for Google crawler to hit to get info.
  # }
  #
  # Issues the following errors along with corresponding HTTP response codes:
  # 400: "Bad Request" if the request is missing image data.
  # 401: "Unauthorized request" (if certain parameters are present in the
  #      request)
  # 401: "Access token expired" (there is a logged in user, but he doesn't
  #      have a refresh token and his access token is expiring in less than
  #      100 seconds, get a new token and retry)
  # 500: "Error while writing app activity: " + error from client library.
  def create
    current_user = User.find(session[:user_id])
    current_theme = Theme.get_or_create_current
    photo = Photo.from_user_and_theme(current_user, current_theme)
    photo.image = params[:image]
    photo.save!

    token_data = TokenData.from_user(current_user)
    gapi_client = get_gapi_client(token_data)
    photo.post_moment!(gapi_client)

    render json: json_encode(photo, Photo.json_only)
  end

  # Exposed as `DELETE /api/photos`.
  #
  # Accepts the following request parameters.
  #
  # 'photoId': id of the photo to delete.
  #
  # Returns the following JSON response representing success.
  # "Photo successfully deleted."
  #
  # Issues the following errors along with corresponding HTTP response codes:
  # 401: "Unauthorized request" (if certain parameters are present in the
  #      request)
  # 404: "Photo with given ID does not exist."
  def delete
    photo_id = params[:photoId]
    photo = Photo.find(photo_id)

    if (photo.nil?)
      raise Exceptions::PhotoHuntError.new(404, 'Photo with given ID does not exist')
    elsif (photo.owner_user_id != session[:user_id])
      raise Exceptions::PhotoHuntError.new(404, 'Photo with given ID does not exist')
    else
      photo.destroy
    end

    # TODO(samstern): Figure out why this method works but the Android client
    # reports failure
    render json: 'Photo successfully deleted'
  end

  # Exposed as `POST /api/images`.
  #
  # Creates and returns a URL that can be used to upload an image for a
  # photo.
  #
  # Takes no request payload.
  #
  # Returns the following JSON response representing an upload URL:
  #
  # {
  #   "url": "<some_upload_url>"
  # }
  #
  # Issues the following errors along with corresponding HTTP response codes:
  # 401: "Unauthorized request"
  def get_url
    photos_base = "#{request.protocol}#{request.host}:#{request.port}"

    render json: { url: "#{photos_base}/api/photos" }
  end

  # Exposed as `GET /photo.html`
  #
  # Renders an HTML page with schema.org microdata for a particular Photo.
  #
  # Accepts the following request parameters:
  #
  # 'photoId': id of the photo to get.
  def photo
    @photo = Photo.find(params[:photoId])
    @redirect_url = "/index.html?photoId=#{params[:photoId]}"
    render layout: false
  end

end
