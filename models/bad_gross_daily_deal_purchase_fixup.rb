class BadGrossDailyDealPurchaseFixup < DailyDealPurchaseFixup
  validates_presence_of :new_gross_price
end
