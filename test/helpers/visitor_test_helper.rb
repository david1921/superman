module VisitorTestHelper
  CARRIERS            = %w{ t-mobile verizon att virgin qwest cricket }
  
  # Disallowed states ME, WA, HI, ND, AK are not in this list
  STATE_ABBREVIATIONS = %w{ AL AS AZ AR CA CO CT DE DC FM FL GA GU ID IL IN IA
                            KS KY LA MH MD MA MI MN MS MO MT NE NV NH NJ NM NY 
                            NC MP OH OK OR PW PA PR RI SC SD TN TX UT VT VI VA 
                            WV WI WY AE AA AE AE AE AP }
  
  def random_carrier
    CARRIERS[rand * CARRIERS.size]
  end
  
  def random_email
    "test_#{(rand * 1_000_000_000).to_i}@domain#{(rand * 10).to_i}.net"
  end
  
  def random_name
    "Test Name#{(rand * 1_000_000_000).to_i}"
  end

  def random_phone_number
    phone_number = "1"
    10.times { phone_number << (rand * 10).to_i.to_s }
    phone_number
  end
  
  def random_state_code
    STATE_ABBREVIATIONS[rand * STATE_ABBREVIATIONS.size]
  end
  
  def random_ip
    "#{(rand * 1_000).to_i}.#{(rand * 1_000).to_i}.#{(rand * 1_000).to_i}.#{(rand * 1_000).to_i}"
  end

  def random_cdr_sid
    Array.new(16) { rand(10).to_s }.join
  end

  def random_conversion_value
    rand(10000)/100.0
  end
end

