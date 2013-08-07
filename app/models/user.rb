# User of the PhotoHunt application.  This instance maintains all information
# needed to interact with and manage a single user.  That includes things like
# their tokens for social services or third-party APIs, their role within
# PhotoHunt, their profile information, etc.
#
# Data members of this class are intentionally public in order to allow Gson
# to function effectively when generating JSON representations of the class.
#
# Author:: samstern@google.com (samstern)
#
class User < ActiveRecord::Base
  include PlusUtils

  # google_user_id - UUID of the User within Google products.
  #
  # google_display_name - display name tha the User has chosen for Google
  #   products.
  #
  # google_public_profile_url - public Google+ profile URL for this User.
  #
  # google_public_profile_photo_url - public Google+ profile image for this
  #   User.
  #
  # google_expires_at - expiration time in milliseconds since Epoch for this
  #   User's googleAccessToken.
  attr_accessible :google_user_id, :google_display_name,
                  :google_public_profile_url, :google_public_profile_photo_url,
                  :google_expires_at

  # Allows the instance method 'photos' which returns an array of Photos
  # that have owner_user_id equal to the id of this User.  Will be destroyed
  # upon deletion of the User.
  has_many :photos, foreign_key: :owner_user_id, dependent: :destroy

  # Allows the instance method 'votes' which returns an array of Votes
  # that have owner_user_id equal to the id of this User.  Will be destroyed
  # upon deletion of the User.
  has_many :votes, foreign_key: :owner_user_id, dependent: :destroy

  # Allows the instance method 'directedusertouseredges' which returns
  # an array of DirectedUserToUserEdges that have owner_user_id equal to the
  # id of this User.  Will be destroyed upon deletion of the User.
  has_many :directedusertouseredges, class_name: :DirectedUserToUserEdge,
    foreign_key: :owner_user_id, dependent: :destroy

  # The properties that should be displayed when the User is rendered
  # as JSON.
  @@json_only = [:id, :google_user_id, :google_display_name,
                 :google_public_profile_url, :google_public_profile_photo_url,
                 :google_expires_at]

  # Get the json_only class variable.
  def self.json_only
    @@json_only
  end

  # Create a User from a JSON object, which is returned from the
  # plus.people.get API call.
  def self.from_json(user_info)
    new(
      google_user_id: user_info['id'],
      google_display_name: user_info['displayName'],
      google_public_profile_url: user_info['url'],
      google_public_profile_photo_url: user_info['image']['url'])
  end

  # Return an array of the ids of all Users that this User has a
  # DirectedUserToUserEdge pointing to.
  def friend_ids
    directedusertouseredges.map(&:friend_user_id)
  end

  # Return an array of User objects for all Users that this User
  # has a DirectedUserToUserEdge pointing to.
  def friends
    friends = User.where(id: friend_ids)
    return friends
  end

  # Return all of the Photos that were uploaded by Users that this
  # user has a DirectedUserToUserEdge pointing to.
  def friend_photos
    Photo.where(owner_user_id: friend_ids)
  end

  # Query Google+ for the UUIDs of all people that this User has in circles.
  def self.gplus_friend_ids(client, pageToken)
    # TODO(samstern): Cache this
    plus = client.discovered_api('plus')

    parameters = { userId: 'me', collection: 'visible' }
    if (!pageToken.nil? && !pageToken.empty?)
      parameters[:pageToken] = pageToken
    end

    people_result = client.execute(
      api_method: plus.people.list,
      parameters: parameters
    )

    people_parsed = people_result.data
    people_ids = people_parsed['items'].map{ |x| x['id'] }

    next_page_token = people_parsed['nextPageToken']

    if (!next_page_token.nil? && !next_page_token.empty?)
      # Recurse and get the next page of circled users
      return people_ids.concat(User.gplus_friend_ids(client, next_page_token))
    else
      # No more pages, return the collection of UUIDs
      return people_ids
    end
  end

end
