# Represents a User's Photo in PhotoHunt.  Contains all of the properties that
# allow the Photo to be rendered and managed.
#
# Author:: samstern@google.com (Sam Stern)
#
class Photo < ActiveRecord::Base
    include PlusUtils

    # image - the attached file representing the actual image on the filesystem.
    #   Attached and configured via the paperclip gem.
    #
    # owner_user_id - the id of the User that owns this Photo.
    #
    # owner_display_name - the full name of the User that owns this Photo.
    #
    # owner_profile_photo - the url to the profile photo of the User that owns
    #   this Photo.
    #
    # owner_profile_url - the url of the Google+ profile of the User that owns
    #   this Photo.
    #
    # theme_id - the id of the Theme for which this Photo was submitted.
    #
    # theme_display_name - the display name for the Theme to which this
    #   Photo belongs.
    #
    # created - the Date when this Photo was creatd.
    attr_accessible :image, :owner_user_id, :owner_display_name,
                    :owner_profile_photo, :owner_profile_url, :theme_id,
                    :theme_display_name, :created

    # Configure how Paperclip handles the attached upload.  Creates an attached
    # file in the image attribute which has a full size and a 'square' size
    # which is resized to 400x400 and used for display in the application.
    has_attached_file :image, styles: { square: "400x400#" }

    # Allows the instance method 'user' which points to the owner User's
    # record by finding the User model with id equal to the owner_user_id.
    belongs_to :user, foreign_key: :owner_user_id

    # Allows the instance method 'theme' which points to the owner Theme's
    # record by finding the Theme model with id equal to the theme_id.
    belongs_to :theme, foreign_key: :theme_id

    # Allows the instance method 'votes' which returns a list of all Vote
    # that have a photo_id equal to this Photo's id.  When this Photo is
    # destroyed all its votes will be destroyed as well.
    has_many :votes, foreign_key: :photo_id, dependent: :destroy

    # The methods that should be called as virtual attributes when the
    # Photo is rendered as JSON.
    @@json_methods = [:full_size_url, :thumbnail_url, :num_votes, :voted,
                     :vote_cta_url, :photo_content_url ]

    # The objects attributes that should be included when the Photo is
    # rendered as JSON.
    @@json_attrs = [:id, :owner_user_id, :owner_display_name, :owner_profile_url,
                    :owner_profile_photo, :theme_id, :theme_display_name, :created]

    # Get the json_methods class variable.
    def self.json_methods
        @@json_methods
    end

    # Get all of the attributes and methods that should be included in JSON.
    def self.json_only
        @@json_methods.concat(@@json_attrs)
    end

    # Create a new Photo from a User object and a Theme object
    def self.from_user_and_theme(user, theme)
      new(
        owner_user_id: user.id,
        owner_display_name: user.google_display_name,
        owner_profile_photo: user.google_public_profile_photo_url,
        owner_profile_url: user.google_public_profile_url,
        theme_id: theme.id,
        theme_display_name: theme.display_name,
        created: Date.today)
    end

    # Get the Url to the full size image, as it was originally uploaded.
    def full_size_url
      ApplicationController.base_url + image.url
    end

    # Get the Url to the 400x400 size of the image.
    def thumbnail_url
      ApplicationController.base_url + image.url(:square)
    end

    # Get the number of votes that have been cast on this Photo.
    def num_votes
      votes.count
    end

    # Set @voted to true if the User with id userId has voted on this Photo,
    # false otherwise.
    def set_voted_from_user_id(userId)
      if !(userId.nil?)
        votes = Vote.where(owner_user_id: userId, photo_id: id)
        @voted = !(votes.empty?)
      end
    end

    # Setter for the voted attribute
    def voted=(status)
      @voted = status
    end

    # Get the voted attribute.  True if the current user has voted on this
    # Photo, false otherwise.
    def voted
      if @voted.nil?
        return false
      else
        return @voted
      end
    end

    # URL for vote call to action on this Photo.
    def vote_cta_url
      ApplicationController.base_url + "/index.html?photoId=#{id}&action=vote"
    end

    # URL for interactive posts and deep linking on this Photo.
    def photo_content_url
      ApplicationController.base_url + "/photo.html?photoId=#{id}"
    end

    # Post an App Activity to Google+ representing this Photo.
    def post_moment!(client)
      moment = {
        'type' => 'http://schemas.google.com/AddActivity',
        'target' => {
          'url' => photo_content_url
        }
      }

      plus = get_plus(client)
      result = client.execute!(:api_method => plus.moments.insert,
        :parameters => {'userId' => 'me', 'collection' => 'vault'},
        :body_object => moment,
        :headers => {'Content-Type' => 'application/json'})
    end

end
