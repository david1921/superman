require 'crypt/rijndael'

module ConsumersHelper
  def activate_consumer_url(consumer, options = {})
    publisher = consumer.publisher
    options.reverse_merge!( :activation_code => consumer.activation_code, :host => publisher.daily_deal_host, :protocol => "http" )
    activate_publisher_consumers_url(publisher, options)
  end

  # The CYD contest link requires encryption so that users cannot guess the user ID
  # of other users and CYD can ensure that traffic is coming from the AA platform.
  #
  # The URL is built using the following pattern:
  #
  #  http://contest.claimyouredeal.com/contest/viewContest/userId:<encrypted user id>,token:<hashed token>,key:<random key string>
  def cyd_contest_link(consumer)
    result = "http://contest.claimyouredeal.com/contest/viewContest/userId:"
    random_key = generate_random_key
    result << encrypted_consumer_id(consumer, random_key)
    result << ",token:"
    result << hashed_token(random_key)
    result << ",key:"
    result << random_key
    result
  end

  def options_for_locale_select(publisher)
    publisher.enabled_locales_for_consumer.map { |locale| [locale_full_name(locale), locale] }.sort_by { |x| x[0] }
  end

  private

  def locale_full_name(locale)
    Locales::Enabled::FULL_NAMES[locale]
  end

  # Encrypts the user ID using AES encryption. The encyption key provided by CYD
  # is combined with the random key that we generate to form the full encryption
  # key. Then the encrypted key is Base64 encoded for transit.
  def encrypted_consumer_id(consumer, random_key)
    encryptor = Crypt::Rijndael.new(AppConfig.cyd_encryption_key + random_key)
    encrypted_consumer_id = encryptor.encrypt_block(padded_consumer_id(consumer))
    Base64.encode64(encrypted_consumer_id).gsub!("\n", "")
  end

  # The shared token key that CYD has provided is also hashed with the random key,
  # and hashed again using the encryption key. CYD will compare hashes on their end
  # to verify authenticity.
  def hashed_token(random_key)
    first_step = Digest::MD5.hexdigest(AppConfig.cyd_token_key + random_key)
    Digest::MD5.hexdigest(first_step + AppConfig.cyd_encryption_key)
  end

  # Stackoverflow-special for generating a random 8-character key for each request
  def generate_random_key
    (0...8).map { 65.+(rand(25)).chr }.join
  end

  def padded_consumer_id(consumer)
    consumer.id.to_s.ljust(16)
  end
  
end
