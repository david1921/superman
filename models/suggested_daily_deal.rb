class SuggestedDailyDeal < ActiveRecord::Base
  belongs_to :publisher
  belongs_to :consumer

  validates_presence_of :publisher
  validates_presence_of :description

  after_create :send_email_to_publisher

  private

  def send_email_to_publisher
    if publisher.suggested_daily_deal_email_address.present?
      PublishersMailer.deliver_suggested_daily_deal(publisher, self)
    end
  end
end
