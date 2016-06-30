module Import
  module Advertiser
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def import(path)
        errors = []
        error = false
        advertiser_ids = []
        publisher_ids = []
        row_index = 1

        ::Advertiser.transaction do
          publishing_group = PublishingGroup.find_or_create_by_name("Local.com")

          FasterCSV.parse(text_from_file(path), :headers => true) do |row|
            publisher = find_or_create_publisher(row, publishing_group)
            advertiser = find_or_create_advertiser(row, publisher)
            find_or_create_store row, advertiser

            advertiser_ids << advertiser.id
            publisher_ids << publisher.id

            unless Rails.env.test?
              if row_index % 10 == 0
                STDOUT.write row_index
              end
              STDOUT.write error ? "*" : "."
              STDOUT.flush
            end

            row_index = row_index + 1
          end

          publishing_group.advertisers.find(:all, :conditions => [ "advertisers.id not in (?)", advertiser_ids ]).each do |advertiser|
            advertiser.destroy
          end
        end
        
        unless Rails.env.test?
          puts
          errors.each { |error| puts error }
        end
      end
      
      def text_from_file(path)
        converted_text = Iconv.iconv("UTF-8", "WINDOWS-1252", File.read(path)).join
        # Replace double-quotes with two single-quotes so FasterCSV will import
        converted_text.gsub!(/([^,])"([^,\n|\r])/, "\\1''\\2")
        converted_text.gsub!(/([^,])"([^,\n|\r])/, "\\1''\\2")

        # LOCM garbage
        converted_text.gsub("\032", "")
      end
      
      def find_or_create_publisher(row, publishing_group)
        publisher_name = (row["szSiteName"] || row["SiteName"]).gsub("''", "\"")
        publisher_label = row["SiteID"]
        
        publisher = publishing_group.publishers.find(:first, :conditions => [ "label = ?", publisher_label ])
        if publisher
          publisher.name = publisher_name
          publisher.save!
        else
          publisher = publishing_group.publishers.create!(
            :label => publisher_label,
            :name => publisher_name, 
            :self_serve => true,
            :can_create_advertisers => false,
            :advertiser_has_listing => true,
            :default_offer_search_distance => 10,
            :do_strict_validation => false
          )
        end
        publisher
      end
      
      def find_or_create_advertiser(row, publisher)
        listing = row["lAdvertiserID"]
        name = row["BusinessName"].gsub("''", "\"")

        advertiser = ::Advertiser.find_by_listing(listing)
        if advertiser
          advertiser.publisher = publisher
          advertiser.name = name
          advertiser.save!
        else
          advertiser = publisher.advertisers.create!(:name => name, :listing => listing)
        end
        
        advertiser
      end

      def find_or_create_store(row, advertiser)
        if row["Address"].present?
          if advertiser.store.nil?
            # Support older version of Advertiser for LOCM
            if advertiser.respond_to? :build_store
              advertiser.build_store(
                :phone_number => row["PhoneNumber"], 
                :address_line_1 => row["Address"],
                :city => row["City"],
                :state => row["State"],
                :zip => row["Zipcode"]
              ).save!
            else
              advertiser.stores.create!(
                :phone_number => row["PhoneNumber"], 
                :address_line_1 => row["Address"],
                :city => row["City"],
                :state => row["State"],
                :zip => row["Zipcode"]
              )
            end
          else
            advertiser.store.update_attributes(
              :phone_number => row["PhoneNumber"], 
              :address_line_1 => row["Address"],
              :city => row["City"],
              :state => row["State"],
              :zip => row["Zipcode"]
            )
          end
        else
          if advertiser.store.nil?
            # No address, no store: nothing to do
          else
            advertiser.store.destroy
          end
        end
      end
    end
  end
end
