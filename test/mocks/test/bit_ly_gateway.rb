class BitLyGateway
  include Singleton

  def shorten(uri, login, api_key)
    "http://bit.ly/#{uri.hash}"
  end
end
