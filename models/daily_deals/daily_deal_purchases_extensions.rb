module DailyDeals::DailyDealPurchasesExtensions
  def build(*attrs)
    if proxy_owner.non_voucher_deal?
      purchase = NonVoucherDailyDealPurchase.new(*attrs)
    else
      purchase = DailyDealPurchase.new(*attrs)
    end

    purchase.daily_deal = proxy_owner
    purchase
  end

  alias_method :new, :build
end
