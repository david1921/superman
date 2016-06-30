module BraintreeHelper
  def braintree_merchant_account_attrs(publisher, key = :merchant_account_id)
    %w{ test production }.include?(Rails.env) && (merchant_account_id = merchant_account_id(publisher)) ? { key => merchant_account_id } : {}
  end
  
  def braintree_custom_field_attrs(item_code, publisher)
    fields = { :custom_fields => {} }
    if publisher.try(:send_litle_campaign)
      fields[:custom_fields][:litle_report_group] = merchant_account_id(publisher)
      fields[:custom_fields][:litle_campaign]     = item_code
    else
      fields[:custom_fields][:litle_report_group] = merchant_account_id(publisher)
    end
    fields
  end
  
  def braintree_protected_data_for_customer_credit_card(consumer, options = {})
    consumer.in_vault ? braintree_create_credit_card_data(consumer, options) : braintree_create_customer_data(consumer, options)
  end

  def braintree_transaction_data(daily_deal_purchase, options = {})
    use_vault = options.delete :use_vault
    Braintree::TransparentRedirect.transaction_data(:redirect_url => braintree_redirect_url(daily_deal_purchase, options),
                                                    :transaction => braintree_transaction_options(daily_deal_purchase, use_vault, options))
  end
  
  def braintree_error_messages(braintree_result)
    messages = []
    if braintree_result
      if braintree_result.errors
        messages += braintree_result.errors.map(&:message)
      elsif braintree_result.message
        messages << braintree_result.message
      end
    end
    if messages.any?
      title = I18n.t('daily_deal_purchases.braintree_buy_now_form.payment_error_message_header')
      items = messages.map { |message| "<li>#{message}</li>" }
      %(<div class="daily_deal_purchase_errors"><h3>#{title}</h3><ul>#{items}</ul></div>).html_safe
    else
      ""
    end
  end

  private

  def braintree_redirect_url(daily_deal_purchase, options)
    return options[:redirect_url] if options[:redirect_url].present?
    redirect_host = options[:redirect_host] || daily_deal_purchase.publisher.daily_deal_host
    redirect_url_options = { :host => redirect_host }
    redirect_url_options.merge!(:format => options[:redirect_format]) if options[:redirect_format].present?
    braintree_redirect_daily_deal_purchase_url(daily_deal_purchase, redirect_url_options)
  end

  def braintree_transaction_options(daily_deal_purchase, use_vault = false, options = {})
    consumer = daily_deal_purchase.consumer
    transaction = {
      :type => "sale",
      :amount => "%.2f" % daily_deal_purchase.total_price,
      :order_id =>  daily_deal_purchase.analog_purchase_id,
      :options => {
          :submit_for_settlement => AppConfig.capture_on_purchase
      }
    }
    transaction.merge! :payment_method_token => options[:payment_method_token].strip if options[:payment_method_token].present?
    transaction.merge! braintree_merchant_account_attrs(daily_deal_purchase.publisher)
    transaction.merge! braintree_custom_field_attrs(daily_deal_purchase.item_code, daily_deal_purchase.publisher)
    if use_vault
      transaction.merge! braintree_customer_data_for_vault(consumer)
      transaction[:options].merge! :add_billing_address_to_payment_method => true
    end

    transaction
  end

  def braintree_customer_data_for_vault(consumer)
    if consumer.in_vault
      { :customer_id => consumer.id_for_vault }
    else
      { :customer => { :id => consumer.id_for_vault } }
    end
  end

  #
  # Use this tr_data to add a card to the vault for a consumer that isn't in the vault yet.
  #
  def braintree_create_customer_data(consumer, options)
    redirect_url_options = { :host => options[:redirect_host] }
    redirect_url_options.merge!(:format => options[:redirect_format]) if options[:redirect_format].present?
    redirect_url = braintree_customer_redirect_consumer_credit_cards_url(consumer, redirect_url_options)
    
    credit_card_options = { :verify_card => true }
    credit_card_options.merge! braintree_merchant_account_attrs(consumer.publisher, :verification_merchant_account_id)
    customer = { :id => consumer.id_for_vault, :credit_card => { :options => credit_card_options }}

    Braintree::TransparentRedirect.create_customer_data(:redirect_url => redirect_url, :customer => customer)
  end
  #
  # Use this tr_data to add a card to the vault for a consumer that's already in the vault.
  #
  def braintree_create_credit_card_data(consumer, options)
    redirect_url_options = { :host => options[:redirect_host] }
    redirect_url_options.merge!(:format => options[:redirect_format]) if options[:redirect_format].present?
    redirect_url = braintree_credit_card_redirect_consumer_credit_cards_url(consumer, redirect_url_options)
    
    credit_card_options = { :verify_card => true }
    credit_card_options.merge! braintree_merchant_account_attrs(consumer.publisher, :verification_merchant_account_id)
    credit_card = { :customer_id => consumer.id_for_vault, :options => credit_card_options }

    Braintree::TransparentRedirect.create_credit_card_data(:redirect_url => redirect_url, :credit_card => credit_card)
  end

  def merchant_account_id(publisher)
    (publisher.try(:merchant_account_id) || publisher.try(:publishing_group).try(:merchant_account_id)).try(:strip)
  end
end
