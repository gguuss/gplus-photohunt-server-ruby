# The basic controller class for the entire Application.  All other Controllers
# are a subclass of ApplicationController.  Abstracts some common logic and
# controls filters that run before and after every request.  Handles all
# exceptions raised by other controllers.
#
# Author:: samstern@google.com (Sam Stern)
#
class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Exceptions

  # Methods executed as each request is received and before it is executed
  # by a controller.
  before_action :set_base_url

  # Method executed just before each response is sent to the client, after
  # the controller has executed.
  after_action :set_cookies

  # The base url of the application, which will generally be https://host:port.
  # Used to create absolute links to application pages for sharing.
  @base_url = nil

  # The cookie key that the Android mobile client uses to store the Session ID.
  MOBILE_KEY = "JSESSIONID"

  # Get the class instance variable @base_url.
  def self.base_url
    @base_url
  end

  # Set the class instance variable @base_url.
  def self.base_url=(url)
    @base_url = url
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # When a PhotoHuntError is thrown, respond by rendering and error message
  # and responding with the appropriate HTTP Status Code, as JSON.
  rescue_from Exceptions::PhotoHuntError do |e|
    render json: "Error (#{e.code}): #{e.msg}", status: e.code
  end

  private

    # Checks if there is an active session with a signed-in User.  True if
    # there is a user signed in, false otherwise.
    def authorized?
      # TODO(samstern): Check for expired token.
      !(session[:user_id].nil?)
    end

    # Throws a 401 Unauthorized Error which will eventually be displayed to the
    # end user.  Usually used in conjunctions with `authorized?`.
    def deny_access
      raise Exceptions::PhotoHuntError.new(401, 'Unauthorized request')
    end

    # Sets the @base_url class variable from the most recent request.  Called
    # before each request in order to keep @base_url up to date.
    def set_base_url
      ApplicationController.base_url ||=
        "#{request.protocol}#{request.host}:#{request.port}"
    end

    # Checks if the server is sending a Set-Cookie Header with the session ID.
    # Copies the value of that cookie into another Set-Cookie header with the
    # key JSESSIONID.
    def set_cookies
      session_key = request.session_options[:id]

      if(!session_key.nil?)
        # Set the cookie the standard way (Set-Cookie)
        response.set_cookie(MOBILE_KEY, session_key)
        # Set the cookie the way the Android client expects it (set-cookie)
        headers["set-cookie"] = headers["Set-Cookie"]
      end
    end

    # Perform any task in the background by opening a new thread, executing
    # the block, and then closing the Thread's ActiveRecord connection.
    def background(&block)
      Thread.new do
        yield
        ActiveRecord::Base.connection.close
      end
    end

end
