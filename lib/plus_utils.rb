module PlusUtils

  def get_plus(client)
    @@plus ||= client.discovered_api('plus')
  end

end
