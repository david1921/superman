module Publishers::VoucherShipping

  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods
    def voucher_shipping_fee
      3
    end
  end

end
