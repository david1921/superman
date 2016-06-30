# common functionality for controllers that manage an Advertiser's offerings 
# such as coupons(offers) and gift_certificates
module Advertisers::Breadcrumbs
  
  def set_crumb_prefix(advertiser)
    publisher = advertiser.publisher

    if admin?
      add_crumb "Publishers", publishers_path
    end
    if publishing_group?
      add_crumb "Publishers", publishing_group_publishers_path(current_user.company)
    end      
    if admin? || publishing_group? || publisher?
      add_crumb publisher.name if publisher.present?
      add_crumb "Advertisers", publisher_advertisers_path(publisher)
    end
    add_crumb advertiser.name, edit_advertiser_path(advertiser)
  end
end
