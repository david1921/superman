require File.expand_path("lib/html_truncator", RAILS_ROOT)
require 'action_view'

module Report
  module Entertainment

    def self.generate_deal_email_file(publishing_group, csv, labels = nil)
      DealEmailFile.new(publishing_group, labels).generate_deal_email_file(csv)
    end

    class DealEmailFile
      include ::ActionView::Helpers::NumberHelper

      def initialize(publishing_group, publisher_labels = nil)
        @publishing_group = publishing_group
        @publisher_labels = publisher_labels || @publishing_group.publishers.map(&:label)
      end

      def generate_deal_email_file(csv)
        csv << DealEmailFile.column_names
        deals_by_publisher = deals_by_publisher_label
        signups_to_email = {}
        @publishing_group.publishers.all(:order => "created_at DESC, id ASC").select {|p| @publisher_labels.include?(p.label) }.each do |publisher|
          deal = deals_by_publisher[publisher.label]
          unless deal.nil?
            signups(Consumer, signups_to_email, publisher, deal)
            signups(Subscriber, signups_to_email, publisher, deal)
          end
        end
        signups_to_email.each do |email, signup|
          csv << DealEmailFile.column_values(signup, signup[:deal])
        end
      end

      def signups(klass, signups_to_email, publisher, deal)
        klass.find_each(:conditions => ["publisher_id = ?", publisher.id]) do |db_signup|
          signup = signup_hash_from_signup(publisher, db_signup, deal)
          email = signup[:email]
          if !signups_to_email.include?(email)
            signups_to_email[email] = signup
          else
            signups_to_email[email] = blend_signups(signups_to_email[email], signup)
          end
        end
      end

      def blend_signups(signup1, signup2)
        blended = {}
        signup1.keys.each do |key|
          blended[key] = signup1[key].blank? ? signup2[key] : signup1[key]
        end
        blended
      end

      def signup_hash_from_signup(publisher, signup, deal)
        {
            :email => signup.email.strip.upcase,
            :first_name => signup.first_name,
            :city => publisher.market_name_or_city || signup.city,
            :zip_code => signup.zip_code,
            :deal => deal
        }
      end

      def deals_by_publisher_label
        @deals_by_city ||= {}.tap do |hash|
          @publishing_group.todays_deals_by_publisher_label.each do |label, deals|
            deal = deals.find{|d| d.current_featured_window.present?}
            next unless deal.present?
            store = deal.advertiser.stores.first
            hash[label] = deal.attributes.symbolize_keys.merge({
              :deal_id => deal.id,
              :publisher => deal.publisher.label,
              :truncated_description => HtmlTruncator.truncate_html(deal.description, 960),
              :value_proposition => deal.value_proposition? ? deal.value_proposition.strip : "",
              :highlights => deal.highlights? ? deal.highlights.strip : "",
              :dollar_price => number_to_currency(deal.price, :precision => 2),
              :dollar_value => number_to_currency(deal.value, :precision => 2),
              :dollar_savings => number_to_currency(deal.savings, :precision => 2),
              :percent_savings => number_to_percentage(deal.savings_as_percentage, :precision => 0),
              :url => "http://#{deal.publisher.production_host}/daily_deals/#{deal.id}",
              :photo_url => deal.photo.url(:standard),
              :advertiser_name => deal.advertiser.name,
              :advertiser_logo_url => deal.advertiser.logo.url(:normal),
              :multi_store => deal.advertiser.stores.count > 1 ? "Y" : "N",
              :store_address_line_1 => store.try(:address_line_1).to_s.strip,
              :store_city => store.try(:city).to_s.strip,
              :store_state => store.try(:state).to_s.strip,
              :store_zip => store.try(:zip).to_s.strip
            })
          end
        end
      end
      
      def self.column_names
        @columns.keys
      end

      def self.column_values(signup, deal)
        @columns.map do |name, pair|
          field_length, lambda_to_call = pair
          DealEmailFile.clean_field_value(lambda_to_call.call(signup, deal).to_s[0, field_length])
        end
      end

      def self.value_of_field_for_row(column_name, rows, row_index)
        rows[row_index][index_of_column_name(column_name)]
      end

      def self.index_of_column_name(column_name)
        @columns.keys.index(column_name)
      end

      def self.clean_field_value(value)
        value.gsub(/(\t|\n|\|)/, "")
      end

      @columns                              = ActiveSupport::OrderedHash.new
      @columns["EMAIL"]                     = [ 150, lambda { |signup, deal| signup[:email].upcase }]
      @columns["RECIPIENTCITY"]             = [  50, lambda { |signup, deal| signup[:city] }]
      @columns["EMAILSUBJECTLINE"]          = [ 100, lambda { |signup, deal| deal[:value_proposition] }]
      @columns["PRODUCTID"]                 = [  25, lambda { |signup, deal| nil }]
      @columns["PRODUCTSKU"]                = [  25, lambda { |signup, deal| nil }]
      @columns["PRODUCTPRICE"]              = [  25, lambda { |signup, deal| deal[:dollar_price] }]
      @columns["PRODUCTPROMOPRICE"]         = [  25, lambda { |signup, deal| deal[:dollar_savings] }]
      @columns["OFFERUPTOVALUE1"]           = [  50, lambda { |signup, deal| deal[:dollar_value] }]
      @columns["PRODUCTTOTALVALUE"]         = [  25, lambda { |signup, deal| deal[:percent_savings] }]
      # @columns["USERDEFINED1"]              = [ ] #intentionality left blank, see PT story 22054949
      @columns["USERDEFINED2"]              = [  50, lambda { |signup, deal| deal[:publisher] }]
      @columns["FIRSTNAME"]                 = [  50, lambda { |signup, deal| signup[:first_name] }]
      @columns["RECIPIENTZIP"]              = [  25, lambda { |signup, deal| signup[:zip_code] }]
      @columns["RECIPIENTSEGMENT"]          = [  50, lambda { |signup, deal| nil }]
      @columns["RECIPIENTSINCE"]            = [  50, lambda { |signup, deal| nil }]
      @columns["TESTSEGMENT"]               = [  50, lambda { |signup, deal| signup[:city] }]
      @columns["ENDECAKEY1"]                = [ 250, lambda { |signup, deal| deal[:url] }]
      @columns["MERCHANTNAME1"]             = [  50, lambda { |signup, deal| deal[:advertiser_name] }]
      @columns["MERCHANTIMAGEPATH1"]        = [ 250, lambda { |signup, deal| deal[:photo_url] }]
      @columns["MERCHANTIMAGEPATH2"]        = [ 250, lambda { |signup, deal| deal[:advertiser_logo_url] }]
      @columns["MERCHANTMULTILOCATIONFLAG"] = [   1, lambda { |signup, deal| deal[:multi_store] }]
      @columns["OFFERCOPYSHORT1"]           = [ 250, lambda { |signup, deal| deal[:value_proposition] }]
      @columns["OFFERCOPYLONG1"]            = [1000, lambda { |signup, deal| deal[:truncated_description] }]
      @columns["MERCHANTCITY1"]             = [  50, lambda { |signup, deal| deal[:store_city] }]
      @columns["MERCHANTSTATE1"]            = [  50, lambda { |signup, deal| deal[:store_state] }]
      @columns["MERCHANTADDRESS1"]          = [  50, lambda { |signup, deal| deal[:store_address_line_1] }]
      @columns["MERCHANTZIPCODE1"]          = [  25, lambda { |signup, deal| deal[:store_zip] }]
      #  client requested these fields be blank for now
      #  an earlier version has them field in properly (except on :state is mispelled it turns out...)
      @columns["ENDECAKEY2"]                = [ 250, lambda { |signup, deal| nil }]
      @columns["MERCHANTNAME2"]             = [  50, lambda { |signup, deal| nil }]
      @columns["OFFERCOPYSHORT2"]           = [ 250, lambda { |signup, deal| nil }]
      @columns["MERCHANTCITY2"]             = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTSTATE2"]            = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTADDRESS2"]          = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTZIPCODE2"]          = [  25, lambda { |signup, deal| nil }]
      @columns["ENDECAKEY3"]                = [ 250, lambda { |signup, deal| nil }]
      @columns["MERCHANTNAME3"]             = [  50, lambda { |signup, deal| nil }]
      @columns["OFFERCOPYSHORT3"]           = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTCITY3"]             = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTSTATE3"]            = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTADDRESS3"]          = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTZIPCODE3"]          = [  25, lambda { |signup, deal| nil }]
      @columns["ENDECAKEY4"]                = [ 250, lambda { |signup, deal| nil }]
      @columns["MERCHANTNAME4"]             = [  50, lambda { |signup, deal| nil }]
      @columns["OFFERCOPYSHORT4"]           = [ 250, lambda { |signup, deal| nil }]
      @columns["MERCHANTCITY4"]             = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTSTATE4"]            = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTADDRESS4"]          = [  50, lambda { |signup, deal| nil }]
      @columns["MERCHANTZIPCODE4"]          = [  25, lambda { |signup, deal| nil }]
    end

  end

end
