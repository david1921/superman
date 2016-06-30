class PhoneNumber

  def initialize(text, country_code=nil, options={})
    @options = options || {}
    @country = Country.find_by_code(country_code)
    @country ||= Country::US

    @text = text.to_s
    if numeric?
      @text = numbers_only
    else
      @text = @text.upcase
    end

    if @country.phone_number_length.present? && raw_number.length >= @country.phone_number_length && !valid?
      @text = @country.calling_code + @text
    end
  end
  
  def valid?
    if numeric?
      if @options[:allow_seven_digit_phone_numbers] && us_or_ca?
        @text =~ /^([0-9]{7}|#{@country.calling_code}[0-9]{#{@country.phone_number_length}})$/
      else
        if @country.phone_number_length.present?
          @text =~ /^#{@country.calling_code}[0-9]{#{@country.phone_number_length}}$/
        else
          true
        end
      end
    elsif us_or_ca?
      if @options[:allow_seven_digit_phone_numbers] && us_or_ca?
        alnums_only =~ /^(#{@country.calling_code})?[a-z0-9]{7,}$/i
      else
        alnums_only =~ /^#{@country.calling_code}[a-z0-9]{#{@country.phone_number_length},}$/i
      end
    else
      false
    end
  end
  
  def to_attribute_s
    @text
  end
  
  def to_formatted_s
    if raw_number.length == 7
      numeric? ? @text.sub(/(\d{3})(\d{4})/, '\1-\2') : @text
    else
      if numeric?
        if us_or_ca?
          @text.sub(/#{@country.calling_code}(\d{3})(\d{3})(\d{4})/, '(\1) \2-\3')
        elsif @country.uk?
          @text.sub(/#{@country.calling_code}(\d{5})(\d{3})(\d{3})/, '\1 \2 \3')
        else
          @text
        end
      else
        @text[@country.calling_code.length .. -1]
      end
    end
  end
  
  private

  def raw_number
    numeric? ? numbers_only : alnums_only
  end

  def numeric?
    @numeric ||= !(@text =~ /[a-z]/i)
  end
  
  def numbers_only
    @text.gsub(/[^0-9]/, '')
  end

  def alnums_only
    @text.gsub(/[^[:alnum:]]/, '')
  end

  def us_or_ca?
    @country.us? || @country.ca?
  end

end
