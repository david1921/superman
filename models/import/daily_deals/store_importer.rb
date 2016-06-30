module Import
  module DailyDeals
    class StoreImporter < Importer

      def initialize(parent, advertiser, store_hash)
        super(parent)
        @advertiser = advertiser
        @store_hash = store_hash
      end

      def validate
        validate_presence_of(@store_hash, :address_line_1)
        validate_presence_of(@store_hash, :city)
        validate_presence_of(@store_hash, :state)
        validate_presence_of(@store_hash, :zip)
        validate_presence_of(@store_hash, :phone_number)
        validate_presence_of(@store_hash, :listing)
        super
      end

      def find_or_new_model
        store
      end

      def store
        @store ||= ::Store.find_by_advertiser_id_and_listing(@advertiser.id, listing) unless listing.blank?
        @store ||= ::Store.new
      end

      def listing
        @store_hash[:listing]
      end

      def populate_model(store)
        store.advertiser = @advertiser
        store.listing = listing
        store.address_line_1 = @store_hash[:address_line_1]
        store.address_line_2 = @store_hash[:address_line_2]
        store.city = @store_hash[:city]
        store.state = @store_hash[:state]
        store.country = ::Country.find_by_code(@store_hash[:country]) if @store_hash.has_key?(:country)
        store.zip = @store_hash[:zip]
        store.latitude = @store_hash[:latitude]
        store.longitude = @store_hash[:longitude]
        store.phone_number = @store_hash[:phone_number]
      end

      private

      def save_model(model)
        # When advertiser is not valid, saving store raises an exception on a database constraint
        model.advertiser.valid? ? model.save : false
      end
    end
  end
end