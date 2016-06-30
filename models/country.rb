class Country < ActiveRecord::Base
  include Comparable
  
  class NoSuchCountry < RuntimeError
  end

  # Country::US
  # Country::UK
  # etc
  def self.const_missing(const)
    if const.to_s.length == 2
      country = ::Country.find_by_code(const.to_s)
      if country.present?
        return country
      else
        raise NoSuchCountry.new "The country with code [#{const.to_s}] is not in the database."
      end
    end
    super
  end

  validates_uniqueness_of :code

  named_scope :active, :conditions => { :active => true }
  named_scope :inactive, :conditions => { :active => false }

  def self.active_codes
    active.map(&:code)
  end
  
  def self.codes
    self.all.map(&:code)
  end

  def self.postal_code_regex(country_code)
    regex = Country.find_by_code(country_code).try(:postal_code_regex)
    return nil unless regex.present?
    Regexp.new(regex)
  end

  def us_or_ca?
    if us? || ca?
       return true
    end
    return false
  end
  
  # Country::US.us? => true
  # Country::UK.uk? => true
  # Country::US.uk? => false
  def method_missing(method, *args)
    if method.to_s =~ /^[a-z]{2}\?$/
      return self.code == method.to_s.chop.upcase
    end
    super
  end
  
  def to_s
    "#<Country id: #{id} code: #{code} name: #{name} >"
  end
  
  def <=>(other)
    return -1 unless other
    code <=> other.try(:code)
  end
  
end
