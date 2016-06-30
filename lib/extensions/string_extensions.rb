require 'digest/md5'

class String
  # Extract normalized phone number from string. Remove all punctuation. Default to US country code of "1" unless already present.
  #
  # There may be a PhoneNumber class lurking here, but we don't need it yet.
  def phone_digits
    return self if blank?

    _digits = gsub(/\D+/, '')
    if _digits.length == 10
      _digits = "1#{_digits}"
    end
    _digits
  end
  
  def zip_code?
    self.match(/\A\d{5}(-\d{4})?\z/).present?
  end

  def to_latin_1
    Iconv.iconv("LATIN1//IGNORE", "UTF8", self)[0] rescue  self
   end

  def to_ascii(transliterate = false)
    if transliterate
      Iconv.iconv("ASCII//TRANSLIT//IGNORE", "UTF8", self)[0] rescue self
    else
      Iconv.iconv("ASCII//IGNORE", "UTF8", self)[0] rescue self
    end
  end
  #
  # Two levels of scrubbing are needed for SMS message bodies:
  #
  #   1. Contents outside the GSM character set cause messages
  #      to be rejected by the CellTrust gateway.
  #
  #   2. Some characters within the GSM character set accepted
  #      by the CellTrust gateway cause the message to fail to
  #      be delivered to my handset in testing.
  #
  # We'll allow what's left when both of the above are excluded.
  #
  def sms_safe?
    !match(/[^- \w@$!#%&"'()*+,.\/:;<=>?]/n)
  end
  
  def sms_safe
    gsub(/[^- \w@$!#%&"'()*+,.\/:;<=>?]/n, '')
  end
  
  def sms_safe!
    gsub!(/[^- \w@$!#%&"'()*+,.\/:;<=>?]/n, '')
  end
  
  def with_indefinite_article
    first.present? ? (%w{ a e i o u }.include?(first) ? "an " : "a ") << self : ""
  end
  
  def possessive
    strip + (ends_with?("s") ? "'" : "'s")
  end

  def md5
    Digest::MD5.hexdigest(self)
  end

end
