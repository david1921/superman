xml.instruct!(:xml, :version => '1.0')

xml.referrals do
  @referrals.each do |referrer|
    xml.referrer(:id => referrer.id) do
      xml.email           referrer.email
      xml.referral_count  referrer.referral_count
      xml.credits_given   referrer.credits_given
      xml.credit_used     referrer.credit_used
    end
  end
end
