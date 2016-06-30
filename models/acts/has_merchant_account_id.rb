module HasMerchantAccountID
  def self.included(base)
    base.class_eval do
      validates_format_of :merchant_account_id, :with => /\A[\S]*[^\d\s]+[\S]*\z/, :message => "%{attribute} must have one or more non numerical character and no spaces", :allow_blank => true
    end
  end
end
