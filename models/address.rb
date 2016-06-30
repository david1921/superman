class Address < ActiveRecord::Base
  include ActsAsLocation

  acts_as_location
end
