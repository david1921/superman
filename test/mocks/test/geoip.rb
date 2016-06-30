#
# Mock the GeoIP lib in order to remove the dependency for a data file during
# development and testing. Add 'IP' => 'Zip Code' to MockData as needed.
#

class GeoIP
  MockData = {
    "173.164.122.114" => "97211"
  }

  def initialize(file)
    self
  end

  def city(ip)
    if MockData.keys.include?(ip)
      @ip = ip
      self
    else
      nil
    end
  end

  def postal_code
    MockData[@ip]
  end
end
