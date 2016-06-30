module Import
  module DailyDeals
    class AdvertiserImporter < Importer

      def initialize(parent, publisher, advertiser_hash)
        super(parent)
        @publisher = publisher
        @advertiser_hash = advertiser_hash || {}
      end

      def validate
        validate_presence_of(@advertiser_hash, :brand_name)
        validate_presence_of(@advertiser_hash, :logo_url)
        validate_presence_of(@advertiser_hash, :locations)
        validate_presence_of(@advertiser_hash, :listing)
        validate_stores
        super
      end

      def validate_stores
        store_importers.each { |h| h.validate }
      end

      def find_or_new_model
        advertiser
      end

      def listing
        @advertiser_hash[:listing]
      end

      def name
        @advertiser_hash[:brand_name]
      end

      def advertiser
        @advertiser ||= ::Advertiser.find_or_initialize_by_publisher_id_and_listing(@publisher.id, listing) if listing.present?
        @advertiser ||= ::Advertiser.find_by_publisher_id_and_name(@publisher.id, name) if name.present?
        @advertiser ||= ::Advertiser.new
      end

      def populate_model(adv)
        @advertiser = adv
        adv.publisher = @publisher
        adv.name = name
        adv.website_url = @advertiser_hash[:website_url]
        adv.logo = photo(:logo_url, @advertiser_hash[:logo_url])
        adv.listing = listing
        adv.stores = stores
      end

      def locations
        array(safe_hash(@advertiser_hash[:locations])[:location])
      end

      def store_importers
        @store_importers ||= locations.map {|l| StoreImporter.new(self, advertiser, l) }
      end

      def stores
        store_importers.map { |h| h.import }
      end

    end
  end
end