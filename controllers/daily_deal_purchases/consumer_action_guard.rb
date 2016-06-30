module DailyDealPurchases
  module ConsumerActionGuard

    def allow_consumer_action?
      if params[:publisher_id].blank?
        render_404
        false
      elsif params[:consumer_id].blank?
        render_404
        false
      elsif admin? 
        true
      elsif !current_consumer
        redirect_to_daily_deal_login(params[:publisher_id])
        false
      elsif !current_consumer_allowed_access?
        logout_user_and_redirect_to_daily_deal_login(params[:publisher_id])
        false
      else
        true
      end
    end

    def current_consumer_allowed_access?
      current_consumer_matches_params? && current_consumer_allowed_access_to_this_publisher?
    end

    def current_consumer_publisher_matches_params?
      current_consumer.publisher_id.to_s == params[:publisher_id]
    end

    def current_consumer_allowed_access_to_this_publisher?
      return true if current_consumer_publisher_matches_params?
      publisher.allow_consumer_access?(current_consumer)
    end

    def current_consumer_matches_params?
      params[:consumer_id] == current_consumer.id.to_s
    end

    def logout_user_and_redirect_to_daily_deal_login(publisher_id)
      store_location
      logout_keeping_session!
      # we discard the flash here because if the user still
      # does not have access they will get a "Welcome" message
      # just as we autolog them out again and that's confusing
      discard_flash
      redirect_to_daily_deal_login(publisher_id)
    end

    def discard_flash
      flash.discard
    end

    def publisher
      @publisher ||= Publisher.find_by_id(params[:publisher_id])
    end

  end
end
