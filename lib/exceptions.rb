module Exceptions

  # Error class covering all errors that the application can throw.
  # Takes an HTTP Status Code and a Message
  class PhotoHuntError < StandardError

    attr_accessor :code, :msg

    def initialize(code, msg)
      @code = code
      @msg = msg
    end

  end

end