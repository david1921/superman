module PurchaseSessionTestHelper
  def set_purchase_session(options = {})
    case options
      when DailyDealPurchase
        token = options.consumer.purchase_auth_token 
      when Consumer
        token = options.purchase_auth_token
      when String
        token = options
      else
        raise ArgumentError, "Expected DailyDealPurchase, Consumer or String; got #{options.class}"
    end
    session[PurchaseSession::PURCHASE_SESSION_TOKEN_KEY] = token
  end
end
