# Represents a Theme for Photos.
#
# Author:: samstern@google.com (Sam Stern)
#
class Theme < ActiveRecord::Base

	# display_name - the name to display for the Theme.
	#
	# start - the Date when the Theme's hunt should start.
	#
	# created - the Date when the THeme was created.
	attr_accessible :display_name, :start, :created

	# Allows the instance method 'photos' which returns an array of Photos
	# that have themeId equal to the id of this Theme.
	has_many :photos, foreign_key: :theme_id

	# The properties that should be displayed when the Theme is rendered
  # as JSON.
  @@json_only = [:id, :display_name, :created, :start]

  # Get the json_only class variable.
  def self.json_only
    @@json_only
  end

	# Get today's theme.  If there is no theme for today, create the theme
	# 'Beautiful' and the start and created dates to today, then return it.
	def self.get_or_create_current
		today = Date.today
		theme = where(start: today).first
		if theme.nil?
			theme = Theme.new(display_name: 'Beautiful', start: today, created: today)
			theme.save!
		end
		theme
	end

end
