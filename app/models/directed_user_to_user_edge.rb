# Directed edge between two Users, used to construct a directed social graph.
# Data to build these edges can be pulled from various social sources, like
# the Google+ People feed, or your existing data set.
#
# Author:: samstern@google.com (Sam Stern)
#
class DirectedUserToUserEdge < ActiveRecord::Base

  # owner_user_id - the id of the User that owns this relationship.  On
  #   Google+, this means that the User owner_user_id has the User
  #   friend_user_id in their circles
  #
  # friend_user_id - the id of the User representing the friend of the
  #   owner User.  This person does not necessarily have User owner_user_id
  #   in their social graph, which is why the Edge is considered Directed
  attr_accessible :owner_user_id, :friend_user_id

  # Allows the instance method 'user' which points to the owner User's
  # record by finding the User model with id equal to the owner_user_id
  belongs_to :user, foreign_key: :owner_user_id

end
