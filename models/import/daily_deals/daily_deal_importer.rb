module Import
  module DailyDeals
    class DailyDealImporter < Importer

      DISALLOWED_AFFILIATE_STRINGS = %w{ tippr }

      def initialize(parent_nil_okay, publisher, deal_hash)
        super(parent_nil_okay, {:hides_at => :ends_at,
                                :quantity => :quantity_available,
                                :min_quantity => :min_purchase_quantity,
                                :max_quantity => :max_purchase_quantity})
        @publisher = publisher
        @deal_hash = deal_hash
      end

      def find_or_new_model
        daily_deal
      end

      def daily_deal
        @daily_deal ||= @publisher.daily_deals.find_by_listing(listing) if listing.present?
        @daily_deal ||= ::DailyDeal.new
      end

      def validate
        validate_exactly_one_of(@deal_hash, :listing)
        validate_exactly_one_of(@deal_hash, :value_proposition)
        validate_at_most_one_of(@deal_hash, :value_proposition_subhead)
        validate_at_most_one_of(@deal_hash, :short_description)
        validate_exactly_one_of(@deal_hash, :description)
        validate_presence_of(@deal_hash, :terms)
        validate_at_least_one_of(@deal_hash[:terms], :term)
        validate_exactly_one_of(@deal_hash, :photo_url)
        validate_exactly_one_of(@deal_hash, :price)
        validate_exactly_one_of(@deal_hash, :value)
        validate_exactly_one_of(@deal_hash, :starts_at)
        validate_exactly_one_of(@deal_hash, :ends_at)
        validate_at_most_one_of(@deal_hash, :side_start_at)
        validate_at_most_one_of(@deal_hash, :side_end_at)
        validate_at_most_one_of(@deal_hash, :currency)
        validate_at_most_one_of(@deal_hash, :category)
        validate_at_most_one_of(@deal_hash, :facebook_title_text)
        validate_at_most_one_of(@deal_hash, :twitter_status_text)
        validate_at_most_one_of(@deal_hash, :quantity_available)
        validate_at_most_one_of(@deal_hash, :enable_email_blast)
        validate_at_most_one_of(@deal_hash, :affiliate_url)
        validate_at_most_one_of(@deal_hash, :min_purchase_quantity)
        validate_at_most_one_of(@deal_hash, :max_purchase_quantity)
        validate_at_most_one_of(@deal_hash, :location_required)
        validate_at_most_one_of(@deal_hash, :custom_1)
        validate_at_most_one_of(@deal_hash, :custom_2)
        validate_at_most_one_of(@deal_hash, :custom_3)
        validate_at_most_one_of(@deal_hash, :markets)


        validate_at_least_one_of(@deal_hash[:markets], :market) if @deal_hash[:markets]

        validate_affiliate
        advertiser_importer.validate
        super
      end

      def listing
        @deal_hash[:listing]
      end

      def populate_model(deal)
        DailyDeal.logger.info "DailyDealImporter.populate_model for listing #{deal.listing} (#{Time.zone.now})"
        deal.publisher = @publisher
        deal.listing = listing
        deal.value_proposition = @deal_hash[:value_proposition]
        deal.value_proposition_subhead = @deal_hash[:value_proposition_subhead]
        deal.description = TextSanitizer.sanitize(@deal_hash[:description])
        deal.short_description = TextSanitizer.sanitize(@deal_hash[:short_description])
        if internal_category = find_internal_analytics_category(@deal_hash[:category])
          deal.analytics_category_id = internal_category.id
        end
        deal.highlights = textiled_list(safe_hash(@deal_hash[:highlights])[:highlight])
        deal.reviews = textiled_list(safe_hash(@deal_hash[:reviews])[:review])
        deal.terms = textiled_list(translate_gift_certificate_to_promotional_certificate(safe_hash(@deal_hash[:terms])[:term]))
        deal.photo = photo(:photo_url, @deal_hash[:photo_url])
        deal.value = @deal_hash[:value]
        deal.price = @deal_hash[:price]
        deal.start_at = time(@deal_hash[:starts_at])
        deal.hide_at = time(@deal_hash[:ends_at])
        deal.expires_on = date(@deal_hash[:expires_on])
        deal.side_start_at = time(@deal_hash[:side_start_at])  if @deal_hash.has_key?(:side_start_at)
        deal.side_end_at = time(@deal_hash[:side_end_at]) if @deal_hash.has_key?(:side_end_at)
        deal.facebook_title_text = @deal_hash[:facebook_title_text]
        deal.twitter_status_text = @deal_hash[:twitter_status_text]
        deal.upcoming = @deal_hash[:upcoming]
        deal.enable_daily_email_blast = @deal_hash[:enable_email_blast]
        deal.quantity = @deal_hash[:quantity_available]
        deal.min_quantity = @deal_hash[:min_purchase_quantity]
        deal.max_quantity = @deal_hash[:max_purchase_quantity] if @deal_hash.has_key?(:max_purchase_quantity)
        deal.location_required = @deal_hash[:location_required]
        deal.custom_1 = @deal_hash[:custom_1]
        deal.custom_2 = @deal_hash[:custom_2]
        deal.custom_3 = @deal_hash[:custom_3]
        deal.affiliate_url = @deal_hash[:affiliate_url]
        deal.advertiser = advertiser_importer.import
        add_markets(deal, safe_hash(@deal_hash[:markets])[:market])
        set_featured!(deal, @deal_hash[:featured])
        deal.assign_defaults
      end

      def set_featured!(deal, featured)
        # this may look like too much, but we have to normalize the values to ruby bols since ruby doesn't interpret "True" as true and pubs are very good with case sensitive values it seems
        if featured.present? && featured.downcase == "true"
          if deal.featured_deal_overlapping_with_publisher.present?
            failure_message = "Featured Daily Deal #{deal.featured_deal_overlapping_with_publisher} conflicts with import: #{deal.featured_deal_overlapping_with_publisher.start_at.to_s(:short)} - #{deal.featured_deal_overlapping_with_publisher.hide_at.to_s(:short)}"
            raise failure_message
          end
          deal.featured = true
        else
          deal.featured = false
        end
      end

      def advertiser_importer
        @advertiser_importer ||= AdvertiserImporter.new(self, @publisher, @deal_hash[:merchant])
      end

      def add_markets(deal, markets)
        markets = array(markets)
        markets.each do |name|
          market = find_or_create_market(name)
          deal.markets << market unless deal.market_ids.include?(market.id)
        end
      end

      def textiled_list(a)
        a = array(a)
        result = ""
        a.each do |highlight|
          result += "* #{TextSanitizer.sanitize highlight}\n"
        end
        result
      end

      def translate_gift_certificate_to_promotional_certificate(text_fragments)
        return nil if text_fragments.nil?

        remove_gc_wording = proc { |t| t.gsub /gift(\s*)certificate/i, "promotional\\1certificate" }

        case text_fragments
          when String
            remove_gc_wording.call(text_fragments)
          when Array
            text_fragments.map { |t_frag| remove_gc_wording.call(t_frag) }
          else
            raise ArgumentError, "expected text_fragments to be a String or Array, got: #{text_fragments.inspect}"
        end
      end

      def find_or_create_market(name)
        @publisher.markets.find_or_create_by_name(name)
      end

      def xml_response_status
        errors? ? "failure" : "success"
      end

      def xml_response(xml_builder)
        xml_builder.result(:listing => listing, :status => xml_response_status) do
          if valid?
            xml_builder.record_id daily_deal.id
          else
            errors.each do |error|
              xml_builder.error do
                xml_builder.attribute(error.attribute.to_s)
                xml_builder.message(error.message)
              end
            end
          end
        end
      end

      def publisher_time_zone
        ActiveSupport::TimeZone.new @publisher.time_zone
      end

      def time(s)
        if s !~ /[A-Z]/
          publisher_time_zone.parse(s)
        else
          super
        end
      end

      private
      
      def find_internal_analytics_category(category_abbreviation)
        DailyDealCategory.analytics.find_by_abbreviation(category_abbreviation) rescue nil
      end

      def validate_affiliate
        if @deal_hash["affiliate_url"]
          DISALLOWED_AFFILIATE_STRINGS.each do |affiliate_string|
            if @deal_hash["affiliate_url"].include?(affiliate_string)
              add_error(:affiliate_url, "contains a disallowed affiliate")
            end
          end
        end
      end

    end
  end
end
