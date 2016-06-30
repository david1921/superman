module Report
  module Syndication
   
    def self.included(base)
      base.send :extend, ClassMethods
    end
    
    module ClassMethods
    
      # returns all the recipients (on captured purchases only) for the given deal and 
      # it's syndicated deals.  This is primarily for chih to run and get data!
      def all_recipients_on_captured_purchases_for_syndicated_deal(deal_or_id)
        source_deal = deal_or_id.is_a?(DailyDeal) ? deal_or_id : ::DailyDeal.find(deal_or_id)
        deals       = [source_deal] + source_deal.syndicated_deals
        recipients  = []
        deals.each do |deal|
          recipients += deal.daily_deal_purchases.captured(nil).collect(&:recipients).flatten.compact
        end
        puts "Name, Publisher Label, Purchased Time, Address Line 1, Address Line 2, City, State, Zip"
        puts "---------------------------------------------------------------------------------------"
        recipients.each do |r|
          daily_deal_purchase = r.daily_deal_purchase
          puts "#{r.name}, #{daily_deal_purchase.daily_deal.publisher.name}, #{daily_deal_purchase.created_at}, #{r.address_line_1}, #{r.address_line_2}, #{r.city}, #{r.state}, #{r.zip_code}"
        end
        return "Report is done!"
      end
      
    end
    
  end
end