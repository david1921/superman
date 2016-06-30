require File.dirname(__FILE__) + "/../../../test_helper"
               
# hydra class Report::Entertainment::EnrolleeTest
module Report
  module Entertainment
    
    class EnrolleeTest < ActiveSupport::TestCase

      test "when there are no consumers or subscribers we get empty result" do
        publishing_group = Factory(:publishing_group)
        Factory(:publisher, :publishing_group => publishing_group)
        result   = []
        Enrollee.new.generate(publishing_group, result)
        assert_equal 0, result.size, "result: #{result}"
      end
                                                                      
      test "subscribers are in the file" do
        publisher = Factory(:publisher)
        Factory(:subscriber, :publisher => publisher, :email => "subscriber@yahoo.com")
        result = []
        Enrollee.new.generate(publisher.publishing_group, result)
        assert_equal 1, result.size
      end
      
      test "consumers are in the file" do
        publisher = Factory(:publisher)
        Factory(:consumer, :publisher => publisher, :email => "consumer@yahoo.com")
        result = []
        Enrollee.new.generate(publisher.publishing_group, result)
        assert_equal 1, result.size
      end                         
      
      test "subscribers are de-dupped on email" do
        publisher = Factory(:publisher)
        Factory(:subscriber, :publisher => publisher, :email => "subscriber@yahoo.com")
        Factory(:subscriber, :publisher => publisher, :email => "subscriber@yahoo.com")
        result = []
        Enrollee.new.generate(publisher.publishing_group, result)
        assert_equal 1, result.size
      end

      test "consumers and subscribers are cross de-dupped on email" do
        publisher = Factory(:publisher)
        Factory(:subscriber, :publisher => publisher, :email => "someguy@yahoo.com")
        Factory(:consumer, :publisher => publisher, :email => "someguy@yahoo.com")
        result = []
        Enrollee.new.generate(publisher.publishing_group, result)
        assert_equal 1, result.size
      end                         
      
      test "consumers are preferenced to subscribers if emails are duplicated" do
        publisher = Factory(:publisher)
        Factory(:subscriber, :publisher => publisher, :name => "John Peters", :email => "someguy@yahoo.com")
        Factory(:consumer, :publisher => publisher, :first_name => "Jeff", :last_name => "Peters", :email => "someguy@yahoo.com")
        result = []
        Enrollee.new.generate(publisher.publishing_group, result) 
        assert_equal 1, result.size
        assert_equal "Jeff Peters", result[0][9]
      end 
      
      test "consumers are preferenced to subscribers from mulitiple publishers" do
        publishing_group = Factory(:publishing_group)
        Factory(:subscriber, :publisher => Factory(:publisher, :publishing_group => publishing_group), 
                             :name => "John Peters", 
                             :email => "someguy@yahoo.com")
        Factory(:consumer, :publisher => Factory(:publisher, :publishing_group => publishing_group), 
                           :first_name => "Jeff", 
                           :last_name => "Peters", 
                           :email => "someguy@yahoo.com")        
        result = []
        Enrollee.new.generate(publishing_group, result) 
        assert_equal 1, result.size
        assert_equal "Jeff Peters", result[0][9]
      end  
      
      test "generate consumer with market name" do 
        publisher = Factory(:publisher,
                            :address_line_1 => "addr line 1",
                            :city => "Portland",
                            :state => "OR",
                            :zip => "97214",
                            :market_name => "Portland Northeast")
        referrering_consumer = Factory(:consumer, :referrer_code    => "xyz")
        consumer = Factory(:consumer, 
                           :publisher        => publisher,
                           :first_name       => "Jeff", 
                           :last_name        => "Peters", 
                           :email            => "someguy@yahoo.com",
                           :referral_code    => referrering_consumer.referrer_code,
                           :zip_code         => "97214",
                           :activated_at     => Time.utc(2010, 10, 12),
                           :agree_to_terms   => true,
                           :created_at       => Time.utc(2010, 10, 12, 1, 2, 3))  
        credit1 = Factory(:credit, :consumer => consumer, :amount => 10)
        credit2 = Factory(:credit, :consumer => consumer, :amount => 15)
        result = Enrollee.new.generate_consumer(publisher, consumer)
        assert_equal "xyz", result[:campaign_id]  
        assert_equal "someguy@yahoo.com", result[:email]
        assert_equal "97214", result[:zip_code]
        assert_equal "Portland Northeast", result[:market]
        assert_equal "20101012", result[:enrollment_date]
        assert_equal "25.00", result[:promo_credit]
        assert_equal "Y", result[:refer_friend_indicator]
        assert_equal "Y", result[:referred_indicator]
        assert_equal "Jeff Peters", result[:name] 
        assert_equal "Y", result[:agree_to_terms]
      end
      
      
      test "generate consumer without market name" do 
        publisher = Factory(:publisher,
                            :address_line_1 => "addr line 1",
                            :city => "Portland",
                            :state => "OR",
                            :zip => "97214",
                            :market_name => nil)
        referrering_consumer = Factory(:consumer, :referrer_code    => "xyz")
        consumer = Factory(:consumer, 
                           :publisher        => publisher,
                           :first_name       => "Jeff", 
                           :last_name        => "Peters", 
                           :email            => "someguy@yahoo.com",
                           :referral_code    => referrering_consumer.referrer_code,
                           :zip_code         => "97214",
                           :activated_at     => Time.utc(2010, 10, 12),
                           :agree_to_terms   => true,
                           :created_at       => Time.utc(2010, 10, 12, 1, 2, 3))  
        credit1 = Factory(:credit, :consumer => consumer, :amount => 10)
        credit2 = Factory(:credit, :consumer => consumer, :amount => 15)
        result = Enrollee.new.generate_consumer(publisher, consumer)
        assert_equal "xyz", result[:campaign_id]  
        assert_equal "someguy@yahoo.com", result[:email]
        assert_equal "97214", result[:zip_code]
        assert_equal "Portland", result[:market]
        assert_equal "20101012", result[:enrollment_date]
        assert_equal "25.00", result[:promo_credit]
        assert_equal "Y", result[:refer_friend_indicator]
        assert_equal "Y", result[:referred_indicator]
        assert_equal "Jeff Peters", result[:name] 
        assert_equal "Y", result[:agree_to_terms]
      end
      
      test "generate subscriber with other_options city" do 
        publisher = Factory(:publisher,
                            :address_line_1 => "addr line 1",
                            :city           => "Portland",
                            :state          => "OR",
                            :zip            => "97214",
                            :market_name => "Portland Northeast")
        referrering_consumer = Factory(:consumer, :referrer_code    => "abc123")
        subscriber = Factory(:subscriber, 
                             :publisher => publisher,
                             :name => "Jeff Peters", 
                             :email     => "someguy@yahoo.com",
                             :zip_code  => "97214",
                             :referral_code => referrering_consumer.referrer_code,
                             :city => "Boston")
        result = Enrollee.new.generate_subscriber(publisher, subscriber)
        assert_equal "abc123", result[:campaign_id]
        assert_equal "someguy@yahoo.com", result[:email]
        assert_equal "97214", result[:zip_code]
        assert_equal "Boston", result[:market]
        assert_equal subscriber.created_at.utc.strftime("%Y%m%d"), result[:enrollment_date]
        assert_equal "0.00", result[:promo_credit] #subscribers will never have a promo credit since they have to become a consumer
        assert_equal "N", result[:refer_friend_indicator]
        assert_equal "Y", result[:referred_indicator]
        assert_equal "Jeff Peters", result[:name]
        assert_equal "N", result[:agree_to_terms] #subscribers don't have terms to agree to
      end
      
      test "generate subscriber without other_options city" do 
        publisher = Factory(:publisher,
                            :address_line_1 => "addr line 1",
                            :city           => "Portland",
                            :state          => "OR",
                            :zip            => "97214",
                            :market_name => "Portland Northeast")
        referrering_consumer = Factory(:consumer, :referrer_code    => "abc123")
        subscriber = Factory(:subscriber, 
                             :publisher => publisher,
                             :name => "Jeff Peters", 
                             :email     => "someguy@yahoo.com",
                             :zip_code  => "97214",
                             :city => nil,
                             :referral_code => referrering_consumer.referrer_code)
        result = Enrollee.new.generate_subscriber(publisher, subscriber)
        assert_equal "abc123", result[:campaign_id]
        assert_equal "someguy@yahoo.com", result[:email]
        assert_equal "97214", result[:zip_code]
        assert_equal "Portland Northeast", result[:market]
        assert_equal subscriber.created_at.utc.strftime("%Y%m%d"), result[:enrollment_date]
        assert_equal "0.00", result[:promo_credit] #subscribers will never have a promo credit since they have to become a consumer
        assert_equal "N", result[:refer_friend_indicator]
        assert_equal "Y", result[:referred_indicator]
        assert_equal "Jeff Peters", result[:name]
        assert_equal "N", result[:agree_to_terms] #subscribers don't have terms to agree to
      end
    
      test "subscriber with nil referral code" do 
        publisher = Factory(:publisher,
                            :address_line_1 => "addr line 1",
                            :city           => "Portland",
                            :state          => "OR",
                            :zip            => "97214")
        subscriber = Factory(:subscriber, 
                             :publisher => publisher,
                             :name => "Jeff Peters", 
                             :email     => "someguy@yahoo.com",
                             :zip_code  => "97214",
                             :referral_code => nil,
                             :city => "Boston")
        result = Enrollee.new.generate_subscriber(publisher, subscriber)
        assert_equal "", result[:campaign_id]
      end
      
      test "subscriber without referral code has referred indicator with value of N" do 
        publisher = Factory(:publisher,
                            :address_line_1 => "addr line 1",
                            :city           => "Portland",
                            :state          => "OR",
                            :zip            => "97214")
        subscriber = Factory(:subscriber, 
                             :publisher => publisher,
                             :name => "Jeff Peters", 
                             :email     => "someguy@yahoo.com",
                             :zip_code  => "97214",
                             :referral_code => nil,
                             :city => "Boston")
        result = Enrollee.new.generate_subscriber(publisher, subscriber)
        assert_equal "N", result[:referred_indicator]
      end
      
      test "subscriber with no other options has empty campaign id" do 
        publisher = Factory(:publisher,
                            :address_line_1 => "addr line 1",
                            :city           => "Portland",
                            :state          => "OR",
                            :zip            => "97214")
        subscriber = Factory(:subscriber, 
                             :publisher => publisher,
                             :name => "Jeff Peters", 
                             :email     => "someguy@yahoo.com",
                             :referral_code => nil,
                             :zip_code  => "97214")
        result = Enrollee.new.generate_subscriber(publisher, subscriber)
        assert_equal "", result[:campaign_id]
      end
      
      test "consumer with no referral code has empty campaign id" do 
         publisher = Factory(:publisher,
                              :address_line_1 => "addr line 1",
                              :city => "Portland",
                              :state => "OR",
                              :zip => "97214")
          consumer = Factory(:consumer, 
                             :publisher => publisher,
                             :first_name       => "Jeff", 
                             :last_name        => "Peters", 
                             :email            => "someguy@yahoo.com",
                             :referral_code    => nil,
                             :zip_code         => "97214",
                             :activated_at     => Time.utc(2010, 10, 12),
                             :agree_to_terms   => true,
                             :created_at       => Time.utc(2010, 10, 12, 1, 2, 3))
        result = Enrollee.new.generate_consumer(publisher, consumer)
        assert_equal "", result[:campaign_id]
      end
      
      test "consumer with no referral code has referred indicator with value of N" do 
         publisher = Factory(:publisher,
                              :address_line_1 => "addr line 1",
                              :city => "Portland",
                              :state => "OR",
                              :zip => "97214")
          consumer = Factory(:consumer, 
                             :publisher => publisher,
                             :first_name       => "Jeff", 
                             :last_name        => "Peters", 
                             :email            => "someguy@yahoo.com",
                             :referral_code    => nil,
                             :zip_code         => "97214",
                             :activated_at     => Time.utc(2010, 10, 12),
                             :agree_to_terms   => true,
                             :created_at       => Time.utc(2010, 10, 12, 1, 2, 3))
        result = Enrollee.new.generate_consumer(publisher, consumer)
        assert_equal "N", result[:referred_indicator]
      end
      
      test "consumer with no promo credits has promo credit field with value of 0.00" do 
         publisher = Factory(:publisher,
                              :address_line_1 => "addr line 1",
                              :city => "Portland",
                              :state => "OR",
                              :zip => "97214")
          consumer = Factory(:consumer, 
                             :publisher => publisher,
                             :first_name       => "Jeff", 
                             :last_name        => "Peters", 
                             :email            => "someguy@yahoo.com",
                             :zip_code         => "97214",
                             :activated_at     => Time.utc(2010, 10, 12),
                             :agree_to_terms   => true,
                             :created_at       => Time.utc(2010, 10, 12, 1, 2, 3))
        result = Enrollee.new.generate_consumer(publisher, consumer)
        assert_equal "0.00", result[:promo_credit]
      end

      test "subscriber with full url as referral code" do
        publisher = Factory(:publisher,
                            :address_line_1 => "addr line 1",
                            :city           => "Portland",
                            :state          => "OR",
                            :zip            => "97214")
        subscriber = Factory(:subscriber,
                             :publisher => publisher,
                             :name => "Jeff Peters",
                             :email     => "someguy@yahoo.com",
                             :zip_code  => "97214",
                             :referral_code => "10027432<http://deals.entertainment.com/?referral_code=10027432",
                             :city => "Boston")
        result = Enrollee.new.generate_subscriber(publisher, subscriber)
        assert_equal "10027432", result[:campaign_id]
      end

      test "consumer_id is in the file" do
        publisher = Factory(:publisher)
        consumer = Factory(:consumer, :publisher => publisher)
        Enrollee.new.generate(publisher.publishing_group, result = [], :include_header => true)
        assert index = result[0].index('consumer_id')
        assert 2, result.size
        assert_equal consumer.id, result[1][index]
      end
    end  
  end
end               
