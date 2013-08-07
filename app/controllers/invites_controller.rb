# Provides an API for inviting new Users. This controller provides
# the /invite.html end-point, and exposes the following operations:
#
#   GET /invite.html
#
# Author:: samstern@google.com (Sam Stern)
#
class InvitesController < ApplicationController

  # Exposed as `GET /invite.html`.  When requested, reders the template
  # `invite.html.erb` with schema.org microdata for the most recently uploaded
  # photo.
  def invite
    current_theme = Theme.get_or_create_current
    photo = current_theme.photos.first

    if (!photo.nil?)
      @name = "Photo by #{photo.owner_display_name} for" +
        " #{current_theme.display_name} | #photohunt"
      @image_url = photo.thumbnail_url
    else
      @name = ""
      @image_url = "/images/interactivepost-icon.png"
    end

    render layout: false
  end

end
