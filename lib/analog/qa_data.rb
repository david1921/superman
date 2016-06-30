module Analog
  module QaData
    ASSET_PATH = File.join(File.dirname(__FILE__), "..", "..", "assets", "qa_data")

    ADVERTISER_LOGO_PATH = File.open(File.join(ASSET_PATH, "logo.png"))
    DEAL_PHOTO_PATH = File.open(File.join(ASSET_PATH, "donuts.jpg"))

    class << self
      def generate_advertiser(publisher)
        advertiser_attributes = {
          :name => Faker::Company.name,
          :tagline => Faker::Lorem.sentence,
          :website_url => 'http://' + Faker::Internet.domain_name,
          :email_address => Faker::Internet.email,
          :logo => ADVERTISER_LOGO_PATH,
          :description => Faker::Lorem.sentence[0, 40],
          :stores => [generate_new_store]
        }
        advertiser_attributes.merge!({:listing => rand(10000)}) if publisher.advertiser_has_listing
        advertiser_attributes.merge!({:federal_tax_id => rand(10000)}) if publisher.require_federal_tax_id?
        advertiser_attributes.merge!({:revenue_share_percentage => "10"}) if publisher.require_advertiser_revenue_share_percentage?
        advertiser = publisher.advertisers.create(advertiser_attributes)

        raise "Generated invalid advertiser: #{advertiser.errors.full_messages.join(', ')}" unless advertiser.valid?

        advertiser
      end

      def generate_store(advertiser)
        store = generate_new_store
        advertiser.stores << store
        advertiser.save
        store
      end

      def generate_daily_deal(advertiser, options = {})
        last_deal = advertiser.daily_deals.first(:order => "hide_at DESC")
        
        start_at = options[:start_at] || last_deal.try(:hide_at) || 1.day.ago
        hide_at  = start_at + (1 + rand(10)).days

        price = 10 + rand(990)
        
        daily_deal_attributes = {
          :value_proposition => Faker::Lorem.sentence,
          :price => price,
          :value => price + rand(100),
          :quantity => 10 + rand(50),
          :min_quantity => 5,
          :max_quantity => 10,
          :description => generate_paragraphs,
          :short_description => Faker::Lorem.sentence[0, 40],
          :terms => generate_paragraphs,
          :highlights => generate_paragraphs,
          :reviews => generate_paragraphs,
          :start_at => start_at,
          :hide_at => hide_at,
          :analytics_category => DailyDealCategory.first,
          :photo => DEAL_PHOTO_PATH          
        }

        if options[:featured] == false
          daily_deal_attributes.merge!(:side_start_at => daily_deal_attributes[:start_at], :side_end_at => daily_deal_attributes[:hide_at])
        end

        daily_deal_attributes.merge!(:advertiser_revenue_share_percentage => "20")
        daily_deal = advertiser.daily_deals.create(daily_deal_attributes)

        raise "Generated invalid daily deal: #{daily_deal.errors.full_messages.join(', ')}" unless daily_deal.valid?

        daily_deal
      end

      private

      def generate_new_store
        country = Country::US

        begin
          store = Store.new(
            :address_line_1 => Faker::Address.street_address,
            :city => Faker::Address.city,
            :state => Faker::Address.us_state_abbr,
            :zip => Faker::Address.zip_code,
            :phone_number => Faker::PhoneNumber.phone_number,
            :country => country
          )
        end while not store.valid?

        store
      end

      def generate_paragraphs
        Faker::Lorem.paragraphs(1 + rand(4)).join("\n\n")
      end
    end
  end
end
