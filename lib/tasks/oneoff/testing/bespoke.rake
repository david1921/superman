namespace :oneoff do
  namespace :testing do
    namespace :bespoke do
      desc "Generate Bespoke publisher, publishing group and pub group admin user"
      task :bootstrap => :environment do
        # This rake task will probably be run in the "development" and "staging" environments, where Factory Girl may not be loaded
        unless Object.const_defined?(:Factory)
          require 'factory_girl'
          require File.dirname(__FILE__) + "/../../../../test/factories"
        end

        Publisher.transaction do
          publishing_group = PublishingGroup.find_by_label("bespoke") || Factory(:publishing_group, :label => "bespoke", :self_serve => true)
          p "Publishing Group: #{publishing_group.id}"

          user = (User.find_by_login("bespoke-admin") || Factory(:user_without_company, :login => "bespoke-admin", :password => "testing", :password_confirmation => "testing")).tap do |u|
            u.user_companies.create!(:company => publishing_group) unless u.user_companies.any?{|uc| uc.company == publishing_group}
          end
          p "User: #{user.id}"
          user.reload.companies.include?(publishing_group) or raise "Expected user companies to have #{publishing_group.id}. Found #{user.companies.map(&:id).inspect}"

          publisher = Publisher.find_by_label("bespoke-offers") || Factory(:publisher, :label => "bespoke-offers", :publishing_group => publishing_group, :self_serve => true, :allow_daily_deals => true)
          p "Publisher: #{publisher.id}"

          advertiser = Advertiser.find_by_name_and_publisher_id("Bespoke Advertiser", publisher.id) || Factory(:advertiser, :publisher => publisher, :name => "Bespoke Advertiser")
          p "Advertiser: #{advertiser.id}"

          daily_deal = advertiser.daily_deals.first || Factory(:daily_deal, :advertiser => advertiser)
          p "Daily Deal: #{daily_deal.id}"
        end
      end
    end
  end
end