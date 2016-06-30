module DailyDealPurchases
  module Create
    def build_daily_deal_purchase
      consumer = current_consumer_for_publisher?(@publisher) ? current_consumer : @publisher.consumers.build
      consumer.valid? unless consumer.new_record?
      @daily_deal_purchase = ::DailyDealPurchase.setup_with(
        :daily_deal => @daily_deal,
        :consumer => consumer,
        :discount => ::Discount.find_by_uuid(params[:discount_uuid]) || consumer.signup_discount_if_usable,
        :mailing_address => ::Address.new(:country => Country::US),
        :daily_deal_variation => @daily_deal_variation
      )
    end

    def create_daily_deal_purchase
      @daily_deal_purchase = init_purchase_from_request
      @daily_deal_purchase.consumer = find_or_create_consumer_for(consumer_attributes)
      @daily_deal_purchase.assign_signup_discount_if_usable unless @daily_deal_purchase.discount.present?
      @daily_deal_purchase.consumer.store_recipient(@daily_deal_purchase) if params[:consumer_store_recipient]

      if params[:consumer_recipient]
        consumer_recipient = Recipient.find(params[:consumer_recipient])
        @daily_deal_purchase.assign_recipient_from_consumer_recipient(consumer_recipient, @daily_deal_purchase.consumer)
      end

      init_daily_deal_order if valid_consumer_with_shopping_cart?

      unless  @daily_deal_purchase.consumer.force_password_reset?
        if @daily_deal_purchase.valid? && @daily_deal_purchase.consumer.valid? && @daily_deal_purchase.consumer.save_detecting_duplicate_entry_constraint_violation && @daily_deal_purchase.save
          @credit_card_token = checked_credit_card_token(@daily_deal_purchase.consumer, params[:credit_card])
          return :success
        else
          reset_daily_deal_purchase
          return :failure
        end
      end
    end
    
    def update_daily_deal_purchase
      @daily_deal_purchase.set_attributes_if_pending(params[:daily_deal_purchase])
      @daily_deal_purchase.ip_address = request.remote_ip
      @daily_deal_purchase.consumer = find_or_create_consumer_for(consumer_attributes)
      @daily_deal_purchase.assign_signup_discount_if_usable unless @daily_deal_purchase.discount.present?

      unless  @daily_deal_purchase.consumer.force_password_reset?
        if @daily_deal_purchase.valid? && @daily_deal_purchase.consumer.valid? && @daily_deal_purchase.save
          return :success
        else
          reset_daily_deal_purchase
          return :failure
        end
      end
    end

    private
    
    def init_purchase_from_request
      @daily_deal.daily_deal_purchases.build.tap do |purchase|
        purchase.set_affiliate_from_placement_code(cookies[:placement_code])
        purchase.set_attributes_if_pending(params[:daily_deal_purchase]) if params[:daily_deal_purchase].present?
        purchase.visitors_referring_id = cookies[:ref]
        purchase.market_id = cookies[:daily_deal_market_id] if capture_market?(purchase)
        purchase.loyalty_program_referral_code = cookies[:"loyalty_referral_code_#{@daily_deal.id}"] if @daily_deal.enable_loyalty_program?
        purchase.ip_address = request.remote_ip
        purchase.discount_code ||= discount_code_from_discount_uuid
      end
    end

    def capture_market?(purchase)
      cookies[:daily_deal_market_id].present? && purchase.daily_deal.market_belongs_to_daily_deal?(cookies[:daily_deal_market_id].to_i)
    end
    
    def consumer_attributes
      @consumer_attributes ||= begin
        attrs = params[:consumer] || {}
        attrs[:password_confirmation] = attrs[:password] if api_call?
        attrs.reverse_merge :referral_code => cookies[:referral_code], :user_agent => user_agent
      end
    end
    
    # this is used by the mobile api, to get the discount code
    # by looking up the discount by it's uuid.
    def discount_code_from_discount_uuid
      if discount_uuid = (params[:daily_deal_purchase]||{})[:discount_uuid]
        discount = @daily_deal.publisher.discounts.usable.find_by_uuid(discount_uuid)
        discount.code if discount
      end
    end

    def find_or_create_consumer_for(attrs)
      load_consumer_from_session_for_json_request
      consumer = consumer_for_current_user_with_side_effects(attrs)
      consumer ||= authenticated_consumer(attrs)
      consumer ||= new_consumer(attrs)
    end

    def consumer_for_current_user_with_side_effects(attrs)
      consumer = current_consumer if current_consumer_for_publisher?(@publisher)
      consumer ||= current_daily_deal_order(@publisher).consumer
      if consumer.present?
        consumer.update_billing_address(attrs)
      end
      consumer
    end
    
    def authenticated_consumer(attrs = {})
      email = attrs[:email].to_s.strip

      # We must first attempt authentication even if the consumer
      # does not exist. In the coolsavings case, for instance,
      # we will go and create the consumer if the email/password
      # authenticate successfully against coolsavings
      consumer = Consumer.authenticate(@publisher, email, attrs[:password])
      if consumer.present?
        set_up_session consumer
        return consumer
      end

      # We don't know yet if the authentication failed because
      # the consumer was inactive or does not exist or
      # simply because the password was bad...
      consumer = @publisher.consumers.find_by_email(email)
      if consumer.nil?
        nil
      elsif consumer.force_password_reset?
        flash[:warn] = translate_with_theme(:password_must_be_reset_message, :scope => :daily_deal_purchases_controller)
        consumer
      elsif consumer.active?
        # authentication failure
        flash[:warn] = translate_with_theme(:account_exists_message, :email => email, :scope => :daily_deal_purchases_controller)
        nil
      else
        # 
        # The account isn't active yet, so reuse the existing record,
        # but update it with the information provided this time.
        #
        consumer.attributes = attrs
        consumer.require_password = true
        consumer.save ? consumer : nil
      end
    end

    def new_consumer(attrs = {})
      consumer = @publisher.consumers.build(attrs)
      consumer.save_detecting_duplicate_entry_constraint_violation
      consumer
    end

    def valid_consumer_with_shopping_cart?
      @daily_deal_purchase.consumer.valid? && @publisher.shopping_cart?
    end
  
    def init_daily_deal_order
      @daily_deal_order = @daily_deal_purchase.consumer.pending_order
      @daily_deal_purchase.daily_deal_order = @daily_deal_order
      session[:daily_deal_order] = @daily_deal_order.uuid
    end
    
    def reset_daily_deal_purchase
      @daily_deal_purchase.clear_discount_if_discount_used_by_another_item_in_cart!
      @daily_deal_purchase.consumer.password = @daily_deal_purchase.consumer.password_confirmation = nil
      @daily_deal_purchase.quantity = 1 unless @daily_deal_purchase.quantity.present?
      @daily_deal_purchase.build_mailing_address unless @daily_deal_purchase.mailing_address
    end
    
    def checked_credit_card_token(consumer, credit_card_param)
      token = credit_card_param[:token] rescue nil
      token.if_present && consumer.credit_cards.find_by_token(token).try(:token)
    end

    def api_call?
      request.format.json?
    end
  end
end
