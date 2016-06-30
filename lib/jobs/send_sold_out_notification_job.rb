
module Jobs
  class SendSoldOutNotificationJob
    include Analog::Say
    @queue = :daily_deal_sold_out_notification

    class << self
      def perform(deal_id)
       raise "Daily Deal Id required as first parameter" unless deal_id.present?
       PublishersMailer.deliver_daily_deal_sold_out_notification(DailyDeal.find(deal_id))
      end
    end  

  end
end