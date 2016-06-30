namespace :oneoff do
  namespace :testing do

    desc "Generate test purchases for any active deals for the given publisher"
    task :generate_on_and_off_platform_purchases => :environment do
      raise "Not allowed to run this in production" if Rails.env.production?
      raise "must pass ENV['PUBLISHER_LABEL']" if ENV['PUBLISHER_LABEL'].blank?
      publisher = Publisher.find_by_label(ENV['PUBLISHER_LABEL'])
      raise "Publisher #{ENV['PUBLISHER_LABEL'].inspect} not found" unless publisher

      DailyDealPurchase.transaction do
        rollback = false
        deals = publisher.daily_deals.active.each do |deal|
          begin
            generate_test_purchases(deal)
          rescue
            rollback = true
            puts "Error generating purchases for deal #{deal.id} (#{deal.value_proposition.inspect}): #{$!.message}"
            raise $!
          end
          raise ActiveRecord::Rollback if rollback
        end
      end
    end

    private

    def generate_test_purchases(deal)
      publisher = deal.publisher
      api_user = Factory(:user, :login => "api-user#{User.maximum(:id) + 1}")
      admin = Factory(:admin, :login => "admin-#{User.maximum(:id) + 1}")
      num = 20

      num.times do |i|
        purchase = nil

        if i.even?
          purchase = Factory(:captured_off_platform_daily_deal_purchase, :daily_deal => deal, :api_user => api_user)
        else
          next_id = Consumer.maximum(:id) + 1
          consumer = Factory(publisher.require_billing_address ? :billing_address_consumer : :consumer, :email => "consumer#{next_id}@test.com", :login => "consumer#{next_id}", :publisher => publisher)
          purchase = Factory(:captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer)
        end

        purchase.daily_deal_certificates.map(&:refund!) if rand(4) == 0 # randomly refund about 25% of the purchases to populate "refunded daily deals" report
      end

      puts "Created #{num} purchases for deal #{deal.id} (#{deal.value_proposition.inspect} @#{deal.advertiser.name})"
    end
  end
end
