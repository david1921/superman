module Accounting::RevenueSharingAgreementsHelper
  
  def platform_revenue_sharing_agreement_edit_url(publishing_group, publisher, daily_deal, platform_revenue_sharing_agreement)
    if publishing_group.present? 
      platform_publishing_group_revenue_sharing_agreement_edit_url(publishing_group, platform_revenue_sharing_agreement)
    elsif publisher.present?
      platform_publisher_revenue_sharing_agreement_edit_url(publisher, platform_revenue_sharing_agreement)
    elsif daily_deal.present?
      daily_deal_platform_revenue_sharing_agreement_url(daily_deal)
    else
      raise "Publishing Group or Publisher required.a"
    end
  end
  
  def platform_publishing_group_revenue_sharing_agreement_edit_url(publishing_group, platform_revenue_sharing_agreement)
    if platform_revenue_sharing_agreement.new_record? 
      publishing_group_platform_revenue_sharing_agreements_url(publishing_group)
    else 
      publishing_group_platform_revenue_sharing_agreement_url(publishing_group, platform_revenue_sharing_agreement)
    end
  end
  
  def platform_publisher_revenue_sharing_agreement_edit_url(publisher, platform_revenue_sharing_agreement)
    if platform_revenue_sharing_agreement.new_record? 
      publisher_platform_revenue_sharing_agreements_url(publisher)
    else 
      publisher_platform_revenue_sharing_agreement_url(publisher, platform_revenue_sharing_agreement)
    end
  end
  
  def syndication_revenue_sharing_agreement_edit_url(publishing_group, publisher, daily_deal, syndication_revenue_sharing_agreement)
    if publishing_group.present? 
      syndication_publishing_group_revenue_sharing_agreement_edit_url(publishing_group, syndication_revenue_sharing_agreement)
    elsif publisher.present?
      syndication_publisher_revenue_sharing_agreement_edit_url(publisher, syndication_revenue_sharing_agreement)
    elsif daily_deal.present?
      daily_deal_syndication_revenue_sharing_agreement_url(daily_deal)
    else
      raise "Publishing Group or Publisher required."
    end
  end
  
  def syndication_publishing_group_revenue_sharing_agreement_edit_url(publishing_group, syndication_revenue_sharing_agreement)
    if syndication_revenue_sharing_agreement.new_record? 
      publishing_group_syndication_revenue_sharing_agreements_url(publishing_group)
    else 
      publishing_group_syndication_revenue_sharing_agreement_url(publishing_group, syndication_revenue_sharing_agreement)
    end
  end
  
  def syndication_publisher_revenue_sharing_agreement_edit_url(publisher, syndication_revenue_sharing_agreement)
    if syndication_revenue_sharing_agreement.new_record? 
      publisher_syndication_revenue_sharing_agreements_url(publisher)
    else 
      publisher_syndication_revenue_sharing_agreement_url(publisher, syndication_revenue_sharing_agreement)
    end
  end
  
end
