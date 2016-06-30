module HasSerialNumber

  MAX_ATTEMPTS_AT_UNIQUENESS = 100

  def self.included(base)
    base.class_eval do
      before_validation_on_create :assign_unique_random_serial_number
      validates_each :serial_number do |record, attr, value|
        unless record.respond_to?(:skip_serial_number_uniqueness_check?) &&
               record.skip_serial_number_uniqueness_check?
          record.errors.add attr, "%{attribute} #{value} is not unique across all certificates" unless record.unique_across_certificates_using_internal_serial_numbers?(value)
        end
      end
      validates_immutability_of :serial_number
    end
  end

  def self.blowfish
    @blowfish ||= Crypt::Blowfish.new('F="*5:\-)B(4v7E2')
  end

  def unique_random_serial_number
    (1..MAX_ATTEMPTS_AT_UNIQUENESS).each do
      possibly_unique_and_random = random_serial_number
      return possibly_unique_and_random if unique_across_certificates_using_internal_serial_numbers?(possibly_unique_and_random)
    end
    raise "Could not create unique serial number after #{MAX_ATTEMPTS_AT_UNIQUENESS} attempts"
  end

  def random_serial_number
    bytes = Array.new(8) { rand(2^8).chr }.join
    encrypted_bytes = ::HasSerialNumber.blowfish.encrypt_block(bytes)
    sprintf("%d%d%d%d-%d%d%d%d", *encrypted_bytes.unpack("C"*8).map { |byte| byte % 10 })
  end

  def unique_across_certificates_using_internal_serial_numbers?(is_this_unique)
    unique_across_internal_serial_numbers_excluding_self?(DailyDealCertificate, is_this_unique) && unique_across_internal_serial_numbers_excluding_self?(PurchasedGiftCertificate, is_this_unique)
  end

  def unique_across_internal_serial_numbers_excluding_self?(model_class, is_this_unique)
    third_party_serials_filter = model_class == DailyDealCertificate ? "AND serial_number_generated_by_third_party != 1" : ""
    if new_record?
      model_class.find(:first, :conditions => ["serial_number = ? #{third_party_serials_filter}", is_this_unique]).nil?
    else
      model_class.find(:first, :conditions => ["id != ? and serial_number = ? #{third_party_serials_filter}", id, is_this_unique]).nil?
    end
  end

  def assign_unique_random_serial_number
    self.serial_number = unique_random_serial_number if serial_number.blank?
  end

end