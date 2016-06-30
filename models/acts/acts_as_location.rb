module ActsAsLocation

  def self.included(base)
    base.extend(ClassMethods)
    base.send :belongs_to, :country, :class_name => "Country"
    base.extend Addresses::Validations
  end

  module ClassMethods
    def acts_as_location(options={})
      class_eval do
        include ActsAsLocation::InstanceMethods

        acts_as_mappable :lat_column_name => :latitude,
                         :lng_column_name => :longitude

        before_validation :normalize_address_fields
        before_validation :assign_country_from_state
        before_validation :reset_region_or_state
        before_create :set_longitude_and_latitude
        before_save :normalize_zip
        before_save :normalize_phone_number

        validates_country :if => proc { |rec| rec.validate_full_address? }
        validates_complete_us_address  :if => proc { |rec| rec.validate_full_address? && rec.located_in_us? }
        validates_complete_ca_address  :if => proc { |rec| rec.validate_full_address? && rec.located_in_ca? }
        validates_complete_international_address :if => proc { |rec| rec.validate_full_address? && !rec.located_in_us_or_ca? }
        validates_state :allow_blank => true
        validates_zip_code :allow_blank => true
        validates_presence_of :phone_number, :message => "%{attribute} and address can't both be blank", :if => proc { |rec| rec.require_address_or_phone? && !rec.address? }
        validates_each :phone_number, :allow_blank => true do |record, attr, value|
          record.errors.add(attr, ::I18n.translate("activerecord.errors.messages.invalid")) unless PhoneNumber.new(value, record.country_code, record.phone_number_options).valid?
        end
      end
    end
  end

  module InstanceMethods

    def zip=(value)
      @zip_as_entered = value
      write_attribute :zip, value.try(:strip)
    end

    def zip_as_entered
      @zip_as_entered || formatted_zip
    end

    def zip_code
      zip
    end

    def zip_code=(z)
      self.zip = z
    end

    def formatted_zip
      if located_in_us?
        zip.to_s.sub(/\A(\d{5})(\d{4})\Z/, '\1-\2')
      elsif located_in_ca?
        zip.to_s.sub(/\A(.{3})(.{3})\Z/, '\1 \2')
      else
        zip
      end
    end

    def normalize_zip
      if country.try(:us_or_ca?)
        write_attribute :zip, zip.to_s.gsub(/[-\s]/, '')
      end
    end

    def phone_number=(value)
      @phone_number_as_entered = value
      write_attribute :phone_number, value.try(:strip)
    end

    def phone_number_as_entered
      @phone_number_as_entered || formatted_phone_number
    end

    def formatted_phone_number(phone_column_name = nil)
      phone_number_to_format = phone_column_name.blank? ? send(:phone_number) : send(phone_column_name)
      PhoneNumber.new(phone_number_to_format, country_code, phone_number_options).to_formatted_s
    end

    def normalize_phone_number
      write_attribute :phone_number, PhoneNumber.new(phone_number, country_code, phone_number_options).to_attribute_s unless phone_number.blank?
    end

    def address?
      [address_line_1, address_line_2, city, state, zip].any?(&:present?)
    end

    def phone_number?
      phone_number.try(:present?)
    end

    def require_complete_address?
      true
    end

    def require_address_or_phone?
      true
    end

    def validate_full_address?
      address? && require_complete_address?
    end

    def address
      if located_in_us_or_ca?
        lines = returning([]) do |array|
          line = [address_line_1, address_line_2].reject(&:blank?).join(", ")
          array << line if line.present?

          line = [state, formatted_zip].reject(&:blank?).join(" ")
          line = [city, line].reject(&:blank?).join(", ")
          array << line if line.present?
        end
      else
        lines = returning([]) do |array|
          array << address_line_1 if address_line_1.present?
          array << address_line_2 if address_line_2.present?
          array << city if city.present?
          array << region if region.present?
          array << zip if zip.present?
          array << country.name unless !country.present? || array.empty?
        end
      end
      if block_given?
        lines.each { |line| yield(line) }
      else
        lines
      end
    end

    def normalize_address_fields
      %w{ address_line_1 address_line_2 city state }.each do |attr|
        write_attribute attr, read_attribute(attr).try(:split, ' ').try(:join, " ")
      end
      self.state = state.try(:strip).try(:upcase)
    end

    def address_mappable?
      if located_in_us_or_ca?
        [address_line_1, city, state].all?(&:present?)
      else
        [address_line_1, city, country].all?(&:present?)
      end
    end

    def google_map_url(name)
      if address_mappable?
        if located_in_us_or_ca?
          query_params = "%s, %s, %s %s (%s)" % [address_line_1, city, state, zip, name]
        else located_in_uk?
          query_params = "%s, %s, %s %s (%s)" % [address_line_1, city, country.name, zip, name]
        end
        "http://maps.google.com/maps?li=d&hl=en&f=d&iwstate1=dir:to&daddr=#{CGI.escape(query_params)}"
      end
    end

    def assign_country_from_state
      return if country.present?
      return unless state.present?
      if Addresses::Codes::US::STATE_CODES.include? state
        self.country = Country::US
      end
    end

    def reset_region_or_state
      if located_in_us_or_ca?
        write_attribute :region, nil
      else
        write_attribute :state, nil
      end
    end

    def located_in_us_or_ca?
      !country.present? || country.try(:us_or_ca?)
    end

    def located_in_ca?
      country.try(:ca?)
    end

    def located_in_us?
      country.try(:us?)
    end

    def located_in_uk?
      country.try(:uk?)
    end

    def country_code
      country.try(:code)
    end

    def summary
      if address?
        if located_in_us_or_ca?
          [address_line_1, city, state].select(&:present?).join ", "
        else
          [address_line_1, city, country.try(:code)].select(&:present?).join ", "
        end
      elsif phone_number.present?
        formatted_phone_number
      elsif new_record?
        "New #{self.class.name}"
      else
        "Blank"
      end
    end

    def set_longitude_and_latitude(force=false)
      do_initialize   = [:longitude, :latitude].all? { |attr| respond_to?(attr) && send(attr).blank? && respond_to?("#{attr}=".to_sym) }
      do_initialize &&= respond_to?(:address_for_google_geocoding)

      if force || do_initialize
        geocode = Geokit::Geocoders::GoogleGeocoder.geocode(address_for_google_geocoding)
        if geocode.success?
          self.longitude = geocode.lng
          self.latitude  = geocode.lat
        end
      end
    end

    def set_longitude_and_latitude!(force=false)
      set_longitude_and_latitude(force)
      save
    end

    def latitude_and_longitude_present?
      begin
        latitude.present? && longitude.present?
      rescue
        return false
      end
    end

    def phone_number_options
      if self.respond_to? :allow_seven_digit_phone_numbers
        {:allow_seven_digit_phone_numbers => allow_seven_digit_phone_numbers}
      end
    end

  end
end
