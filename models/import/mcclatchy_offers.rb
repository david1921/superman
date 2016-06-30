require "net/ftp"

module Import
  module McclatchyOffers

    def self.download_and_import_offers_for_today(ftp_server, username, password, remote_filter = nil)
      download_and_import_offers_for_date(ftp_server, username, password, Date.today, remote_filter)
    end

    def self.download_and_import_offers_for_date(ftp_server, username, password, date, remote_filter = nil)
      download_offers_for_date(ftp_server, username, password, date, remote_filter).each { |local_file| import_offers(local_file) }
    end

    def self.download_offers_for_date(ftp_server, username, password, date, remote_filter = nil)
      local_files = []
      Net::FTP.open(ftp_server) do |ftp|
        ftp.login(username, password)
        ftp.nlst.select {|f| f.ends_with?("#{date.strftime("%Y%m%d")}.xml")}.each do |remote_file|
          if filter_matches(remote_file, remote_filter)
            local_file = File.expand_path("tmp/mcclatchy_#{remote_file}", RAILS_ROOT)
            puts "ftp #{remote_file} to #{local_file}"
            ftp.get remote_file, local_file
            local_files << local_file
          else
            puts "skipping remote file because it does not match filter: #{remote_file}"
          end
        end
      end
      local_files
    end

    def self.filter_matches(remote_file, remote_filter)
      remote_filter.nil? || remote_file =~ remote_filter
    end

    def self.import_offers(file_path)
      puts "Importing offers from #{file_path}."
      raise ArgumentError, "Basename of file path must include publisher label" unless File.basename(file_path) =~ /_.*_(.*)_/
      publisher = Publisher.find_by_label($1)
      raise ArgumentError, "No publisher matches that label: #{$1}" unless publisher
      File.open(file_path, "r") do |file|
        importer = McclatchyOffersImporter.new(publisher, file).parse_and_save_offers!
        puts "   Saved #{importer.offers.size} new offers."
        if importer.errors.present?
          puts "   Errors:"
          importer.errors.each do |coupon_node, exception|
            puts "     Coupon ID #{coupon_node.xpath("couponId").text}: #{exception}"
          end
        end
      end
    end

    class McclatchyOffersImporter

      attr_reader :offers, :errors

      def initialize(publisher, xml_string_or_file)
        @publisher = publisher
        @doc = Nokogiri::XML(xml_string_or_file)
        @offers = []
        @errors = []
      end

      def parse_and_save_offers!
        @doc.xpath("//feed/coupons/coupon").each do |coupon_node|
          begin
            Offer.transaction { @offers << create_offer!(coupon_node) }
          rescue Exception => e
            @errors << [coupon_node, e]
          end
        end
        self
      end

      private

      def create_offer!(coupon_node)
        offer = Offer.new
        offer.listing = coupon_node.xpath("couponId").text if @publisher.offer_has_listing?
        offer.show_on = time_from_node(coupon_node, "startDate")
        offer.expires_on = time_from_node(coupon_node, "endDate")
        offer.coupon_code = coupon_node.xpath("couponCode").text
        offer.terms = coupon_node.xpath("details").text
        offer.value_proposition = coupon_node.xpath("title").text
        offer.message = coupon_node.xpath("title").text
        offer.txt_message = clean_sms_text(offer.value_proposition)
        offer.value_proposition_detail = coupon_node.xpath("subtitle").text
        offer.advertiser = create_or_find_advertiser(coupon_node.xpath("advertiser"))
        offer.category_names = parse_category_names(coupon_node)
        offer.photo = store_photo_locally_and_get_file(coupon_node.xpath("couponPhotoUrl").text)
        image_file = store_photo_locally_and_get_file(coupon_node.xpath("couponPhotoUrl").text)
        if image_file
          offer.offer_image = image_file
          image_file.close unless image_file.closed?
        end
        offer.save!
        offer
      end

      def clean_sms_text(txt)
        return if txt.nil?
        (txt.size > 80 ? txt[0, 80] + "..." : txt).sms_safe
      end

      def create_or_find_advertiser(advertiser_node)
        advertiser_name = advertiser_node.xpath("businessName").text
        advertiser = ::Advertiser.find_by_publisher_id_and_name(@publisher.id, advertiser_name)
        # return advertiser if advertiser
        if advertiser.nil? 
          advertiser = ::Advertiser.new
          advertiser.publisher = @publisher
          advertiser.listing = advertiser_node.xpath("listingId").text if @publisher.advertiser_has_listing?
          advertiser.name = advertiser_name
        end
        
        advertiser.coupon_clipping_modes = [:email]
        advertiser.website_url = advertiser_node.xpath("businessWebUrl").text
        advertiser.save!

        advertiser_locations = advertiser_node.xpath("locations/location")
        advertiser.stores.delete_all if advertiser.stores.count
        advertiser_locations.each do |location_node|
          store = advertiser.stores.create(
            :address_line_1 => location_node.xpath("address/addr1").text,
            :address_line_2 => location_node.xpath("address/addr2").text,
            :city => location_node.xpath("address/city").text,
            :state => location_node.xpath("address/province").text,
            :latitude => location_node.xpath("address/lat").text,
            :longitude => location_node.xpath("address/lon").text,
            :phone_number => location_node.xpath("phone").text
          )
        end

        advertiser
      end

      def time_from_node(node, xpath)
        Time.parse(node.xpath(xpath).text)
      end

      # categories can only be 2 levels deep
      def parse_category_names(coupon_node)
        all_categories = []
        coupon_node.xpath("categories/category").map do |category_node|
          children = category_node.xpath("category")
          if children.empty?
            all_categories << category_node["name"]
          else
            all_categories += children.map { |child| "#{category_node["name"]}:#{child["name"]}" }
          end
        end
        all_categories.join(", ")
      end

      def store_photo_locally_and_get_file(photo_url)
        return nil if photo_url.blank?
        File.new(download_and_store_photo(photo_url, File.expand_path("tmp/mcclatchy_#{File.basename(photo_url)}", RAILS_ROOT)))
      end

      def download_and_store_photo(photo_url, local_path)
        puts "download_and_store_photo:#{local_path}"
        File.open(local_path, "w+") do |file|
          file.puts(Net::HTTP.get(URI.parse(photo_url)))
        end
        local_path
      end

    end
  end
end
