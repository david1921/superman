class PublishingGroupSubscribersController < ApplicationController
  include Publishers::Themes
  layout with_theme("landing_pages")

  ssl_allowed :create

  before_filter :set_publishing_group
  
  def create
    if should_create_publisher_subscriber
      create_publisher_subscriber
    else
      create_publishing_group_subscriber
    end
  end
  
  def thank_you
    analytics_tag.signup!
    render with_theme
  end

  private

  def try_to_create_subscriber_for_default_publisher_in_group(publishing_group)
    if publisher = publishing_group.default_publisher_for_subscribers
      subscriber = publisher.subscribers.build((params[:subscriber] || {}).reverse_merge(:referral_code => cookies[:referral_code], :user_agent => user_agent))
      subscriber.save ? subscriber : nil
    end
  end

  def zip_code_valid_for_publishing_group?(zip_code, publishing_group)
    zip_code_regex =
      Country.postal_code_regex(publishing_group.country.try(:code)) ||
      Country.postal_code_regex(Country::US.code)
    zip_code =~ zip_code_regex
  end

  def should_create_publisher_subscriber
    params[:publisher_label].present? ||
      params[:publisher_id].present? ||
      params[:redirect_to_deal_page].present? ||
      params[:assign_subscriber_to_publisher_by_zip_code].present?
  end

  def create_publisher_subscriber
    @publisher = find_publisher_by_zip_code_label_or_id

    if @publisher.nil?
      zip_as_entered = params[:subscriber][:zip_code] rescue nil
      if zip_as_entered.present? && !zip_code_valid_for_publishing_group?(zip_as_entered, @publishing_group)
        flash[:warn] = 
          translate_with_theme(:zip_code_is_invalid, :zip_code => zip_as_entered, :scope => :publishing_group_subscribers_controller)
        redirect_to :back
      else
        @subscriber = try_to_create_subscriber_for_default_publisher_in_group(@publishing_group) if zip_as_entered.present?
        flash[:warn] = publisher_not_found_message
        redirect_when_publisher_not_found
      end
    else
      @subscriber = @publisher.subscribers.build((params[:subscriber] || {}).reverse_merge(:referral_code => cookies[:referral_code], :user_agent => user_agent))
      handle_new_subscriber
    end
  end

  def publisher_not_found_message
    if params[:assign_subscriber_to_publisher_by_zip_code].present?
      if normalized_subscriber_zip_code_based_on_guessing_country_code.present?
        translate_with_theme(:publisher_zip_code_not_found_message, :scope => :publishing_group_subscribers_controller)
      else
        translate_with_theme(:publisher_zip_code_required_message, :scope => :publishing_group_subscribers_controller)
      end
    else
      translate_with_theme(:publisher_not_found_message, :scope => :publishing_group_subscribers_controller)
    end
  end

  def create_publishing_group_subscriber
    @subscriber = @publishing_group.subscribers_with_no_market.build((params[:subscriber] || {}).reverse_merge(:referral_code => cookies[:referral_code], :user_agent => user_agent))
    handle_new_subscriber
  end

  def handle_new_subscriber
    if @subscriber.save
      cookies[:subscribed] = "subscribed"
      flash[:notice] = translate_with_theme(:subscription_success_message)
    else
      flash[:warn] = translate_with_theme(:subscription_failure_message, :errors => @subscriber.errors.full_messages.join(". "))
    end

    if @subscriber.valid?
      cookies[:publisher_label] = { :value => @publisher.label, :expires => 10.years.from_now } if @publisher.present?

      if params[:redirect_to_deal_page]
        redirect_url = public_deal_of_day_url(@publisher.label)
      else
        redirect_url = verify_url(params[:redirect_to]) || thank_you_publishing_group_subscribers_url(@publishing_group.label)
      end
      redirect_to(redirect_url)
    else
      redirect_to :back
    end
  end

  def find_publisher_by_zip_code_label_or_id
    label_or_id = params[:publisher_label] || params[:publisher_id]

    if label_or_id.present?
      @publishing_group.publishers.find_by_label_or_id(label_or_id)
    elsif normalized_subscriber_zip_code_based_on_guessing_country_code.present? && params[:assign_subscriber_to_publisher_by_zip_code].present?
      publisher_by_zip_code
    end
  end

  def redirect_when_publisher_not_found
    if normalized_subscriber_zip_code_based_on_guessing_country_code.present?
      redirect_to(verify_url(params[:publisher_not_found_redirect_to]) || :back)
    else
      redirect_to :back
    end
  end

  def normalized_subscriber_zip_code_based_on_guessing_country_code
    if params[:subscriber] && params[:subscriber].has_key?(:zip_code)
      zip_code = params[:subscriber][:zip_code]
      guessed_country = @publishing_group.publishers.first.try(:country)
      if guessed_country == Country::US
        zip_code.to_s.gsub(/\D/, "")[0..4]
      else
        zip_code
      end
    end
  end

  # For US, the suscribers zip code is 12345-1234 sometimes but we need only the first 5 digits to find the publisher by the zip code
  def publisher_by_zip_code
    @publishing_group.publisher_zip_codes.find_by_zip_code(normalized_subscriber_zip_code_based_on_guessing_country_code).try(:publisher)
  end

  def set_publishing_group
    @publishing_group = PublishingGroup.find_by_label!(params[:publishing_group_id])
  end
end
