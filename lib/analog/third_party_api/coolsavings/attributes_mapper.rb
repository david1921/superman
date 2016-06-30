# This class maps a hash of coolsavings attributes describing a coolsavings member to
# a hash of attributes describing an analog consumer and vice versa.
class Analog::ThirdPartyApi::Coolsavings::AttributesMapper

  # Fields from the coolsavings payload we are not mapping:
  #"MEMBER_SINCE"=>"2011-09-16 13:25:51",
  #"MAIL_DEALS"=>"0",
  #"SALUTATION"=>"1",
  #"UPDATED"=>"2011-09-16 13:25:51",
  #"PHONE"=>"5032315432",
  #"MAIL_PARTNERS"=>"0",
  #"AGE"=>"",
  #"BIRTHDAY"=>"1950-10-10",

  TO_ANALOG = {
    "EMAIL"=>"email",
    "STREET"=>"address_line_1",
    "CITY"=>"billing_city",
    "STATE"=>"state",
    "ZIP"=>"zip_code",
    "FNAME" => "first_name",
    "LNAME"=>"last_name",
    "COUNTRY"=>"country_code",
    "GENDER"=>"gender" }
  TO_COOL = TO_ANALOG.invert

  def map_to_analog(coolsavings_hash)
    map(coolsavings_hash, TO_ANALOG)
  end

  def map_to_coolsavings(analog_hash)
    map(analog_hash, TO_COOL)
  end

  def map(hash, mapping)
    result = {}
    hash.each_pair do |key,val|
      if mapping.has_key?(key)
        result[mapping[key]] = val
      end
    end
    result
  end

end
