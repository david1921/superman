class ConsumerReferralUrl < ActiveRecord::Base
  include HasBitLyUrl

  belongs_to :consumer
  belongs_to :publisher

  private

  def url_for_bit_ly
    consumer.referral_url_for_bit_ly(publisher)
  end
end
