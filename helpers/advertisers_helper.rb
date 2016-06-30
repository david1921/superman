module AdvertisersHelper

  def can_edit_store_listing?
    current_user or return false
    admin_user?(current_user) || entertainment_group_user?(current_user)
  end

  def entertainment_group_user?(user)
    epg = entertainment_group() or return false
    user.companies.include?(epg)
  end

  def can_delete_coupon?(user)
    user.has_full_admin_privileges? || user.has_restricted_admin_privileges?
  end

  def show_subscription_notice?(advertiser)
    advertiser_user_for_paid_advertiser_with_offers?(advertiser) && !advertiser_subscribed_or_returning_from_paypal?(advertiser)
  end

  def show_welcome_notice?(advertiser)
    advertiser_user_for_paid_advertiser_with_offers?(advertiser) && advertiser_subscribed_or_returning_from_paypal?(advertiser) && !advertiser.approved?
  end

  def show_approved_checkbox?(advertiser)
    advertiser.paid? && (admin? || publisher?)
  end

  def advertiser_match?(advertiser)
    if params[:advertiser_name].present? && advertiser.present?
      advertiser_letter = params[:advertiser_name].upcase+params[:advertiser_name].downcase
      advertiser.name.match(/^[#{advertiser_letter}](.+||)/)
    end
  end

  def can_create_publisher_advertiser?(publisher)
    admin? || publisher.can_create_advertisers?
  end


  private

  def admin_user?(user)
    user && user.has_full_admin_privileges?
  end

  def entertainment_group
    PublishingGroup.find_by_label('entertainment')
  end

  def advertiser_user_for_paid_advertiser_with_offers?(advertiser)
    !admin? && !publisher? && !advertiser.new_record? && advertiser.paid? && advertiser.offers.present?
  end

  def advertiser_subscribed_or_returning_from_paypal?(advertiser)
    advertiser.subscribed? || advertiser.recent_return_from_paypal?
  end
end
