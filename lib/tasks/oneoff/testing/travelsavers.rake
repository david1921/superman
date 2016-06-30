namespace :oneoff do
  namespace :testing do
    namespace :travelsavers do

      desc "Generate Travelsaver deals for integration testing"
      task :generate_deals => :environment do

        # This rake task will probably be run in the "development" and "staging" environments, where Factory Girl may not be loaded
        if Rails.env.test?
          unless Object.const_defined?(:Factory)
            require 'factory_girl'
            require File.dirname(__FILE__) + "/../../../../test/factories"
          end
        end

        raise "Not allowed to run this in production" if Rails.env.production?
        raise "Specify distributing publisher with ENV['DISTRIBUTING_PUBLISHER_LABEL']" if ENV['DISTRIBUTING_PUBLISHER_LABEL'].blank?
        distributing_publisher = Publisher.find_by_label(ENV['DISTRIBUTING_PUBLISHER_LABEL'])
        publishers_category = distributing_publisher.publishing_group.daily_deal_categories.select{|c| c.name == "Syndicated" }.first || distributing_publisher.publishing_group.daily_deal_categories.create!(:name => "Testing")
        raise "Publisher #{ENV['DISTRIBUTING_PUBLISHER_LABEL'].inspect} not found" unless distributing_publisher
        raise "#{distributing_publisher.name} is not in the syndication network" unless distributing_publisher.in_syndication_network?
        travelsavers = Publisher.find_by_label!('travelsavers')
        raise "Payment method is not 'travelsavers' for Travelsavers" unless travelsavers.payment_method == 'travelsavers'
        raise "Travelsavers is not in the syndication network" unless travelsavers.in_syndication_network?
        advertiser = travelsavers.advertisers.last || Factory(:advertiser, :publisher => travelsavers)

        start_at = Time.parse("2012-03-15 00:00:00")
        hide_at = Time.parse("2012-06-15 00:00:00")
        [
            ["TST-2-1", "Booking sent to vendor, vendor returns error, return sold out cabin error. (TST-2-1)", {}],
            ["TST-2-2", "Booking sent to vendor, credit card error returned. (TST-2-2)", {}],
            ["TST-3-1", "Error accessing transaction information, database unavailable error. (TST-3-1)", {}],
            ["TST-4-1", "Error accessing booking record from vendor, communication error. (TST-4-1)", {}],
            ["TST-S-1", "Successful booking, successful payment. (TST-S-1)", {:price => 2000, :value => 4000}],
            ["TST-S-2", "Successful booking, payment pending for 5 mins. (TST-S-2)", {:price => 2000, :value => 4000}],
            ["TST-S-3", "Pending booking, payment pending for 60 seconds. (TST-S-3)", {:price => 2000, :value => 4000}],
            ["TST-S-6", "Successful booking, failed payment. (TST-S-6)", {}]
        ].each do |product_code, description, attrs|
          begin
            DailyDeal.transaction do
              if ts_deal = DailyDeal.find_by_travelsavers_product_code_and_publisher_id(product_code, distributing_publisher.id)
                puts "Deal for #{product_code} already exists"
              else
                ts_deal = Factory(:daily_deal_for_syndication,
                    {
                                  :advertiser => advertiser,
                                  :travelsavers_product_code => product_code,
                                  :value_proposition => description,
                                  :value_proposition_subhead => description,
                                  :description => description,
                                  :analytics_category => DailyDealCategory.analytics.last,
                                  :start_at => start_at,
                                  :hide_at => hide_at,
                                  :side_start_at => start_at,
                                  :side_end_at => hide_at,
                                  :advertiser_revenue_share_percentage => 0.10
                    }.merge(attrs)
                )
                puts "Created deal #{product_code}"
              end

              if dist_deal = DailyDeal.find_by_travelsavers_product_code_and_publisher_id(product_code, distributing_publisher.id)
                puts "Deal for #{product_code} was already syndicated for #{distributing_publisher.label}"
              else
                dist_deal = ts_deal.syndicated_deals.build(
                    :publisher_id => distributing_publisher.id,
                    :publishers_category => publishers_category,
                    :value_proposition => "TRAVELSAVERS - #{ts_deal.value_proposition}",
                    :value_proposition_subhead => "TRAVELSAVERS - #{ts_deal.value_proposition_subhead}",
                    :description => "TRAVELSAVERS - #{ts_deal.description}"
                )
                dist_deal.save!
                puts "Syndicated deal #{product_code}"
              end
            end
          rescue
            puts "Error creating or syndicating deal #{product_code}: " + $!.message
            raise
          end
        end
      end
    end
  end
end