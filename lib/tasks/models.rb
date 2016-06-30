class Advertiser < ActiveRecord::Base
  has_attached_file :logo,
                    :storage => :s3,
                    :bucket => "logos.advertisers.analoganalytics.com",
                    :s3_host_alias => "logos.advertisers.analoganalytics.com",
                    :url => ":s3_path_url",
                    :path => ":rails_env/:id/:style.:extension",
                    :default_url => "http://#{AppConfig.default_host}/images/missing/:class/:attachment/:style.png",
                    :whiny_thumbnails => true,
                    :default_style => :normal,
                    :styles => {
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                          :large => { :geometry => "350x550>", :format => :png },
                         :normal => { :geometry => "240x90>",  :format => :png },
                       :facebook => { :geometry => "130x110>", :format => :png },
                       :standard => { :geometry => "110x60>", :format => :png },
                      :thumbnail => { :geometry => "100x30>",  :format => :png }
                    },
                    :convert_options => { :facebook => "-crop 130x110+0+0! -background white -flatten" },
                    :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml"
end

class DailyDeal < ActiveRecord::Base
  has_attached_file :photo,
                    :storage => :s3,
                    :bucket => "photos.daily-deals.analoganalytics.com",
                    :s3_host_alias => "photos.daily-deals.analoganalytics.com",
                    :url => ":s3_path_url",
                    :path => ":rails_env/:id/:style.:extension",
                    :default_url => "http://#{AppConfig.default_host}/images/missing/:class/:attachment/:style.png",
                    :whiny_thumbnails => true,
                    :default_style => :normal,
                    :styles => { 
                      :standard  => { :geometry => "319x319>", :format => :png },
                      :portrait  => { :geometry => "274x444>", :format => :png },
                      :facebook  => { :geometry => "130x110>", :format => :png },
                      :thumbnail => { :geometry => "100x30>",  :format => :png },
                      :widget    => { :geometry => "112x112>", :format => :png },
                      :email     => { :geometry => "208x252>", :format => :png }
                    },
                    :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml"
end

class GiftCertificate < ActiveRecord::Base
  has_attached_file :logo,
                    :storage => :s3,
                    :bucket => "logos.gift-certificates.analoganalytics.com",
                    :s3_host_alias => "logos.gift-certificates.analoganalytics.com",
                    :url => ":s3_path_url",
                    :path => ":rails_env/:id/:style.:extension",
                    :default_url => "http://#{AppConfig.default_host}/images/missing/:class/:attachment/:style.png",
                    :whiny_thumbnails => true,
                    :default_style => :normal,
                    :styles => {
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                      :normal    => { :geometry => "400x300>",  :format => :png },
                      :medium    => { :geometry => "240x90>",  :format => :png }
                    },
                    :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml"
end

class Offer < ActiveRecord::Base
  has_attached_file :photo,
                    :storage => :s3,
                    :bucket => "photos.offers.analoganalytics.com",
                    :s3_host_alias => "photos.offers.analoganalytics.com",
                    :url => ":s3_path_url",
                    :path => ":rails_env/:id/:style.:extension",
                    :default_url => "http://#{AppConfig.default_host}/images/missing/:class/:attachment/:style.png",
                    :whiny_thumbnails => true,
                    :default_style => :normal,
                    :styles => { 
                      :standard => { :geometry => "128x90>", :format => :png },
                      :normal =>   { :geometry => "200x208>", :format => :png } 
                     },
                     :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml"

  has_attached_file :offer_image,
                    :storage => :s3,
                    :bucket => "offer-images.offers.analoganalytics.com",
                    :s3_host_alias => "offer-images.offers.analoganalytics.com",
                    :url => ":s3_path_url",
                    :path => ":rails_env/:id/:style.:extension",
                    :default_url => "http://#{AppConfig.default_host}/images/missing/:class/:attachment/:style.png",
                    :whiny_thumbnails => true,
                    :styles => {
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                          :large => { :geometry => "350x550>", :format => :png },
                         :medium => { :geometry => "240x90>",  :format => :png },
                      :thumbnail => { :geometry => "100x30>",  :format => :png }
                    },
                    :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml"
end

class Publisher < ActiveRecord::Base
  has_attached_file :logo,
                    :storage => :s3,
                    :bucket => "logos.publishers.analoganalytics.com",
                    :s3_host_alias => "logos.publishers.analoganalytics.com",
                    :url => ":s3_path_url",
                    :path => ":rails_env/:id/:style.:extension",
                    :default_url => "http://#{AppConfig.default_host}/images/missing/:class/:attachment/:style.png",
                    :whiny_thumbnails => true,
                    :default_style => :normal,
                    :styles => {
                      :full_size => { :geometry => "100x100%", :format => :jpg },
                      :normal =>    { :geometry => "240x90>",  :format => :png }
                    },
                    :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml"

  has_attached_file :paypal_checkout_header_image,
                    :storage => :s3,
                    :bucket => "paypal-checkout-header-images.publishers.analoganalytics.com",
                    :s3_host_alias => "paypal-checkout-header-images.publishers.analoganalytics.com",
                    :url => ":s3_path_url",
                    :path => ":rails_env/:id/:style.:extension",
                    :default_url => "http://#{AppConfig.default_host}/images/missing/:class/:attachment/:style.png",
                    :whiny_thumbnails => true,
                    :default_style => :normal,
                    :styles => {
                      :normal => { :geometry => "750x90>", :format => :png },
                       :small => { :geometry => "250x30>", :format => :png },
                    },
                    :s3_credentials => "#{Rails.root}/config/paperclip_s3.yml"
end

