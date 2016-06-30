class Smoke::FakeConsumer

  def initialize(email_to_use, password_to_use)
    @email_to_use = email_to_use
    @password_to_use = password_to_use
  end

  def uuid
    @uuid ||= UUIDTools::UUID.random_create.to_s
  end

  def password
    @password = @password_to_use || 'password'
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def first_name
    @first_name ||= Faker::Name.first_name
  end

  def last_name
    @last_name ||= Faker::Name.last_name
  end

  def email
    @email = @email_to_use || "#{uuid}@yahoo.com"
  end

  def activation_code
    "ZYXW9876"
  end

  def activated_at
    @activated_at ||= Time.now
  end

  def street_address
    @street_address ||= Faker::Address.street_address
  end

  def city
    @city ||= Faker::Address.city
  end

  def zip_code
    @zip ||= Faker::Address.zip_code
  end

  def create_in_db!(publisher)
    consumer = Consumer.new
    consumer.publisher = publisher
    consumer.name = full_name
    consumer.email = email
    consumer.activation_code = activation_code
    consumer.activated_at = activated_at
    consumer.password = password
    consumer.password_confirmation = password
    consumer.agree_to_terms = true
    if publisher.require_billing_address?
      consumer.address_line_1 = street_address
      consumer.billing_city = city
      consumer.state = Faker::Address.state_abbr
      consumer.zip_code = zip_code
      consumer.country_code = publisher.country_codes.first
    end
    if publisher.publisher_membership_codes.size > 0
      consumer.publisher_membership_code_as_text = publisher.publisher_membership_codes.first.code
    end
    consumer.save!
    consumer
  end

end