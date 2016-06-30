class BitLyGateway
  include Singleton

  def shorten(uri, login, api_key)
    # Don't throw a hard error if we have trouble getting bit.ly URL
    uri = uri.to_s
    request = Net::HTTP::Post.new(bit_ly_api_uri.path)
    request.set_form_data({
      "version" => "2.0.1",
      "longUrl" => uri,
      "login" => login || "analog",
      "apiKey" => api_key || "R_f30e934e5fb8a27ef4e1ff79ece1040f"
    })
    response = Net::HTTP.new(bit_ly_api_uri.host, bit_ly_api_uri.port).start do |http|
      http.open_timeout = 1
      http.read_timeout = 2
      http.request(request)
    end
    ActiveSupport::JSON.decode(response.body)["results"][uri]["shortUrl"]
  end
  
  def bit_ly_api_uri
    @@bit_ly_api_uri ||= URI.parse("http://api.bit.ly/shorten")
  end
end
