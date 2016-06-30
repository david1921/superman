class LandingPagesController < ApplicationController
  include Publishers::Themes

  before_filter :load_publishing_group_by_label, :only => [:show]
  before_filter :redirect_to_publisher_based_on_zip_code, :only => [:show]

  layout with_theme("landing_pages")

  def show
    redirect_by_membership_code || redirect_by_publisher_label || redirect_bcbsa_national || render_show
  end
  
  private
  
  def load_publishing_group_by_label
    @publishing_group = PublishingGroup.find_by_label!(params[:publishing_group_id])
  end

  def redirect_bcbsa_national
    if @publishing_group.label == 'bcbsa'
      redirect_to public_deal_of_day_path('bcbsa-national')
      true
    end
  end

  def redirect_by_publisher_label
    if cookies['publisher_label'] && (publisher = @publishing_group.publishers.find_by_label(cookies['publisher_label']))
      redirect_to public_deal_of_day_path(:label => publisher.label)
      true
    end
  end

  def redirect_by_membership_code
    if params[:membership_code]
      @publisher_membership_code = @publishing_group.publisher_membership_codes.find_by_code(params[:membership_code])

      if @publisher_membership_code
        @publisher = @publisher_membership_code.publisher

        set_persistent_cookie(:publisher_membership_code, @publisher_membership_code.code)
        set_persistent_cookie(:publisher_label, @publisher.label)
        set_persistent_cookie(:zip_code, params[:zip_code]) if params[:zip_code].present?

        redirect_to public_deal_of_day_path(@publisher.label)
        true
      else
        cookies.delete(:publisher_membership_code)
        cookies.delete(:publisher_label)

        flash.now[:warn] = "Membership code not found.  Please try again."
        false
      end
    end
  end

  def render_show
    @errors = flash.keys.include?(:warn) ? [flash["warn"]] : []
    render with_theme("show")
  end

  def set_persistent_cookie(key, value)
    cookies[key] = {:value => value, :expires => 1.year.from_now, :secure => https_only_host?}
  end
  
end
