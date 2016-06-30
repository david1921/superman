class Market < ActiveRecord::Base
  validates_presence_of :publisher_id
  validates_uniqueness_of :name, :scope => :publisher_id

  belongs_to :publisher
  has_many :market_zip_codes
  has_and_belongs_to_many :daily_deals

  def label
    name.parameterize("-").to_s
  end
  
  def <=>(other)
    if other.nil?
      -1
    elsif name.nil?
      1
    else
      name <=> other.name
    end
  end
  
  def to_s
    name
  end
end
