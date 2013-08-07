# Provides an API for working with Themes.  This controller provides the
# /api/themes end-point, and exposes the following operations:
#
#   GET /api/themes
#
# Author:  samstern@google.com (Sam Stern)
#
class ThemesController < ApplicationController

  # Exposed as `GET /api/themes`.  When requested, if no theme exists for the
  # current day, then a theme with the name of "Beautiful" is created for
  # today.  This leads to multiple themes with the name "Beautiful" if you
  # use the app over multiple days without changing this logic.  This behavior
  # is purposeful so that the app is easier to get up and running.
  #
  # Returns the following JSON response representing a list of Themes.
  #
  # [
  #   {
  #     "id":0,
  #     "displayName":"",
  #     "created":0,
  #     "start":0
  #   },
  #   ...
  # ]
	def index
    # TODO(samstern): Respect the startIndex and count parameters
		theme = Theme.get_or_create_current
    themes = Theme.all(order: 'start DESC')

    render json: json_encode_array(themes, Theme.json_only)
	end

end
