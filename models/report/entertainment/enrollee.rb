module Report
  module Entertainment

    class Enrollee
      include ActionView::Helpers::NumberHelper
      DATE_FORMAT = "%Y%m%d"

      def generate(publishing_group, file, include_header = false)
        emails = Set.new
        add_header(file) if include_header
        generate_consumers(publishing_group, file, emails)
        generate_subscribers(publishing_group, file, emails)
      end

      def generate_consumers(publishing_group, file, emails)
        publishing_group.publishers.each do |publisher|
          Consumer.find_each(:conditions => ["publisher_id = ?", publisher.id], :include => :publisher, :batch_size => 5_000) do |consumer|
            corresponding_subscriber = Subscriber.find_by_publisher_id_and_email(consumer.publisher.id, consumer.email) unless consumer.email.blank?
            file << generate_consumer(publisher, consumer, corresponding_subscriber).values unless emails.include?(consumer.email)
            emails << consumer.email
          end
        end
      end

      def generate_subscribers(publishing_group, file, emails)
        publishing_group.publishers.each do |publisher|
          Subscriber.find_each(:conditions => ["publisher_id = ?", publisher.id], :include => :publisher, :batch_size => 5_000) do |subscriber|
            file << generate_subscriber(publisher, subscriber).values unless emails.include?(subscriber.email)
            emails << subscriber.email
          end
        end
      end

      def add_header(file)
        header = []
        header << "campaign_id"
        header << "email"
        header << "consumer_id"
        header << "zip_code"
        header << "market"
        header << "enrollment_date"
        header << "promo_credit"
        header << "refer_friend_indicator"
        header << "referred_indicator"
        header << "name"
        header << "agree_to_terms"
        file << header
      end

      def generate_consumer(publisher, consumer, corresponding_subscriber = nil)
        subscriber_referral_code = corresponding_subscriber ? corresponding_subscriber.referral_code : nil
        result = ActiveSupport::OrderedHash.new
        result[:campaign_id] = consumer.referral_code || subscriber_referral_code || ""
        result[:email] = consumer.email
        result[:consumer_id] = consumer.id
        result[:zip_code] = consumer.zip_code
        result[:market] = publisher.market_name_or_city
        result[:enrollment_date] = consumer.activated_at.nil? ? consumer.created_at.utc.strftime(DATE_FORMAT) : consumer.activated_at.utc.strftime(DATE_FORMAT)
        result[:promo_credit] = consumer.credits.empty? ? "0.00" : number_with_precision(consumer.credits.sum("amount"), :precision => 2).to_s
        result[:refer_friend_indicator] = consumer.credits.empty? ? "N" : "Y"
        result[:referred_indicator] = consumer.referred? ? "Y" : "N"
        result[:name] = consumer.name
        result[:agree_to_terms] = consumer.agree_to_terms ? "Y" : "N"
        result
      end

      def generate_subscriber(publisher, subscriber)
        result = ActiveSupport::OrderedHash.new
        result[:campaign_id] = clean_referral_code(subscriber.referral_code) || ""
        result[:email] = subscriber.email
        result[:zip_code] = subscriber.zip_code
        result[:market] = (subscriber.other_options && !subscriber.other_options[:city].blank?) ? subscriber.other_options[:city] : subscriber.market_name
        result[:enrollment_date] = subscriber.created_at.utc.strftime(DATE_FORMAT)
        result[:promo_credit] = "0.00"
        result[:refer_friend_indicator] = "N"
        result[:referred_indicator] = subscriber.referral_code.blank? ? "N" : "Y"
        result[:name] = subscriber.name
        result[:agree_to_terms] = "N"
        result
      end

      def clean_referral_code(referral_code)
        if referral_code =~ /.*\?referral_code=(.*)/
          referral_code = $1
        end
        referral_code
      end
    end
  end
end