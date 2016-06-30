module Consumers::RedirectToLocalDeal

  # tested in  DailyDealsController::Show::RedirectToLocalDealTest
  def redirect_to_users_publisher_deal
    return unless enable_redirect_to_users_publisher? && !consumer_has_purchased_daily_deal?
    if consumer_publisher && @daily_deal.publisher != consumer_publisher
      consumer_publisher_deal = deal_for_publisher(consumer_publisher)
      if consumer_publisher_deal
        # a user belonging to a publisher is viewing a deal at another publisher for which their own publisher has a version of the deal
        redirect_to daily_deal_path(consumer_publisher_deal)
      else
        # a user belonging to a publisher is viewing a deal at another publisher for which their own publisher does not have a  version of the deal
        flash[:notice] = Analog::Themes::I18n.t(consumer_publisher, "daily_deal.not_available")
        redirect_to public_deal_of_day_path(consumer_publisher.label)
      end
    elsif consumer_publisher.nil?
      main_publisher = @daily_deal.publisher.publishing_group.main_publisher || @daily_deal.source.try(:publisher)
      main_publisher_deal = deal_for_publisher(main_publisher)
      if main_publisher_deal && @daily_deal != main_publisher_deal
        # a user who is not logged in and does not have a publisher_label cookie is viewing a  daily_deal at a publisher other than the main publisher
        if main_publisher_deal && main_publisher_deal.show_on_landing_page?
          # the main publisher has hte deal and is showing it on the landing page
          flash[:notice] = Analog::Themes::I18n.t(consumer_publisher, "daily_deal.login_to_view")
          redirect_to daily_deal_path(main_publisher_deal)
        else
          #the main publisher does not have the deal
          flash[:notice] = Analog::Themes::I18n.t(main_publisher, "daily_deal.not_available")
          redirect_to public_deal_of_day_path(main_publisher.label)
        end
      elsif main_publisher
        # a user who is not logged in and does not have the publisher_label cookie is viewing a  deal at the main publisher
        if !@daily_deal.show_on_landing_page?
          #the main publisher is not showing the deal
          flash[:notice] = Analog::Themes::I18n.t(main_publisher, "daily_deal.not_available")
          redirect_to public_deal_of_day_path(main_publisher.label)
        end
      end

    end
  end


  # tested in PublishersController::DealOfTheDayTest
  def redirect_to_local_publisher_if_enable_redirect_to_users_publisher
    return true unless @publisher.try(:publishing_group).try(:enable_redirect_to_users_publisher?)
    if consumer_publisher && @publisher != consumer_publisher
      redirect_to public_deal_of_day_path(consumer_publisher.label)
      false
    elsif consumer_publisher.nil? && !@publisher.main_publisher?
      redirect_to public_deal_of_day_path(@publisher.publishing_group.main_publisher.label)
    else
      true
    end
  end

  # tested in PublishersController::DealOfTheDayTest
  def redirect_to_local_publisher_daily_deals_categories
    return true unless @publisher.try(:publishing_group).try(:enable_redirect_to_users_publisher?)
    if consumer_publisher && @publisher != consumer_publisher
      redirect_to publisher_daily_deal_categories_path(consumer_publisher.id)
      false
    elsif consumer_publisher.nil? && !@publisher.main_publisher? && @publisher.try(:publishing_group).main_publisher
      redirect_to publisher_daily_deal_categories_path(@publisher.publishing_group.main_publisher.id) # redirect to main publisher
    else
      true
    end
  end

  # tested in PublishersController::DealOfTheDayTest
  def redirect_to_local_publisher_daily_deals_category
    return true unless @publisher.try(:publishing_group).try(:enable_redirect_to_users_publisher?)
    if consumer_publisher && @publisher != consumer_publisher
      redirect_to publisher_daily_deal_category_path(:publisher_id => consumer_publisher.id, :id => params[:id])
      false
    elsif consumer_publisher.nil? && !@publisher.main_publisher? && @publisher.try(:publishing_group).main_publisher
      main_publisher = @publisher.publishing_group.main_publisher
      redirect_to publisher_daily_deal_category_path(:publisher_id => main_publisher.id, :id => params[:id]) # redirect to main publisher
    else
      true
    end
  end


  # [br] we really want to say request.format.html? but earlier versions of IE don't explicitly send
  # html in the accept header and mess up request.format so we are instead asking if its anything except html.
  def api_request?
    request.format.json? || request.format.js? || request.format.xml?  || request.format.fbtab?
  end

    def api_request_or_admin_or_consumer_has_master_membership_code?
    api_request? || (current_consumer.try(:has_master_membership_code?) || admin?)
  end

  def redirect_to_current_consumer_publisher_account
    if consumer_publisher && @publisher != consumer_publisher
      redirect_to publisher_consumer_path(:publisher_id => @consumer.publisher.id, :id => @consumer.id)
      return false
    end
    true
  end

  private

  def syndicated_deal_for_publisher(publisher)
    (@daily_deal.source || @daily_deal).syndicated_deals.for_publisher(publisher).first
  end

  def deal_for_publisher(publisher)
    return @daily_deal if @daily_deal.publisher == publisher
    return @daily_deal.source if @daily_deal.source.try(:publisher) == publisher
    (@daily_deal.source || @daily_deal).syndicated_deals.for_publisher(publisher).first
  end

  def render_forbidden
    render :nothing => true, :status => 403
  end

  def enable_redirect_to_users_publisher?
    @daily_deal.publisher.try(:publishing_group).try(:enable_redirect_to_users_publisher?)
  end

  def consumer_publisher
    @consumer_publisher ||= current_user.try(:publisher) || (cookies[:publisher_label] && Publisher.find_by_label(cookies[:publisher_label]))
  end

  def consumer_has_purchased_daily_deal?
    return false unless current_consumer
    current_consumer.daily_deal_purchases.map { |p| p.daily_deal }.include?(@daily_deal)
  end

end
