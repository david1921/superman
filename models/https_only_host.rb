class HttpsOnlyHost < ActiveRecord::Base
  
  validates_presence_of :host
  validates_uniqueness_of :host
  
end