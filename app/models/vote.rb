# Represents a single vote by a single User on a single Photo.
#
# Author:: samstern@google.com (San Stern)
#
class Vote < ActiveRecord::Base
  include PlusUtils

  # photo_id - the id of the Photo on which this Vote was cast.
  #
  # owner_user_id - the id of the User which cast this Vote.
  attr_accessible :photo_id, :owner_user_id

  # Allows the instance method 'photo' which points to the Photo on which this
  # vote was cast and that has id equal to this Vote's photo_id.
  belongs_to :photo, foreign_key: :photo_id

  # Allows the instance method 'user' which points to the User that owns this
  # photo by finding a User with id equal to this Vote's owner_user_id.
  belongs_to :user, foreign_key: :owner_user_id

  # Post an App Activity to Google+ representing this Vote.
  def post_moment!(client)
    moment = {
      'type' => 'http://schemas.google.com/ReviewActivity',
      'target' => {
        'url' => photo.photo_content_url
      },
      'result' => {
        'type' => 'http://schema.org/Review',
        'name' => 'A vote for a PhotoHunt photo',
        'text' => 'Voted!',
        'url' => photo.photo_content_url
      }
    }

    plus = get_plus(client)
    result = client.execute!(:api_method => plus.moments.insert,
      :parameters => {'userId' => 'me', 'collection' => 'vault'},
      :body_object => moment,
      :headers => {'Content-Type' => 'application/json'})
  end

end
