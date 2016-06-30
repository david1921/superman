module DailyDealCertificates::Status

  def set_status!(target_status)
    case target_status
      when 'active'
        activate!
      when 'redeemed'
        redeem!
      when 'refunded'
        refund!
      when 'voided'
        void!
      else
        raise "invalid target status: #{target_status.inspect}"
    end
  end

end