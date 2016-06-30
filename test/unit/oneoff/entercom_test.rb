require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Oneoff::EntercomTest

module Oneoff
  
  class EntercomTest < ActiveSupport::TestCase
    
    fast_context "Oneoff::Entercom.copy_hof_consumers_to_ocala!" do
      
      setup do
        @publishing_group = Factory :publishing_group, :label => "entercomnew"
        @entercom_hof = Factory :publisher, :label => "entercom-gainesville", :publishing_group => @publishing_group
        @entercom_ocala = Factory :publisher, :label => "entercom-ocala", :publishing_group => @publishing_group        
        
        @hof_subscriber = Factory :subscriber, :publisher => @entercom_hof
        @hof_consumer_1 = Factory :consumer_with_name, :publisher => @entercom_hof, :name => "Jacques Pépin", :email => "jp@example.com"
        @hof_consumer_1.update_attribute :remote_record_id, "123"
        @hof_consumer_2 = Factory :consumer_with_name, :publisher => @entercom_hof, :name => "Julia Child", :email => "jc@example.com"
        @hof_consumer_2.update_attribute :remote_record_id, "456"
        
        assert @entercom_ocala.consumers.blank?
        assert_no_difference "ActionMailer::Base.deliveries.size" do
          assert_difference "Consumer.count", 2 do
            Oneoff::Entercom.copy_hof_consumers_to_ocala!
          end
        end
        @hof_consumers = @entercom_ocala.reload.consumers.sort_by(&:name)
      end
      
      should "copy all entercom heart of florida (entercom-gainesville) consumers to ocala" do
        assert_equal 2, @hof_consumers.length
      end
      
      should "copy the name over" do
        assert_equal ["Jacques Pépin", "Julia Child"], @hof_consumers.map(&:name)
      end
      
      should "copy the email over" do
        assert_equal ["jp@example.com", "jc@example.com"], @hof_consumers.map(&:email)
      end
      
      should "copy the crypted password and salt over verbatim" do
        assert_equal [@hof_consumer_1.crypted_password, @hof_consumer_2.crypted_password], @hof_consumers.map(&:crypted_password)
        assert_equal [@hof_consumer_1.salt, @hof_consumer_2.salt], @hof_consumers.map(&:salt)
      end
      
      should "copy the login over" do
        assert_equal ["jp@example.com", "jc@example.com"], @hof_consumers.map(&:login)
      end
      
      should "set the publisher to ocala" do
        assert_equal [@entercom_ocala, @entercom_ocala], @hof_consumers.map(&:publisher)
      end
      
      should "set the type to Consumer" do
        assert @hof_consumers.all? { |c| c.is_a? Consumer }
      end
      
      should "set the first and last names" do
        assert_equal ["Jacques", "Julia"], @hof_consumers.map(&:first_name)
        assert_equal ["Pépin", "Child"], @hof_consumers.map(&:last_name)
      end
      
      should "set the activated_at to non-blank" do
        assert @hof_consumers.all? { |c| c.activated_at.present? }
      end
      
      should "set agree to terms to 1" do
        assert @hof_consumers.all? { |c| c.agree_to_terms? }
      end
      
      should "set signup discount id to nil" do
        assert @hof_consumers.all? { |c| c.signup_discount.nil? }
      end
      
      should "set credit available to 0" do
        assert @hof_consumers.all? { |c| c.credit_available == 0 }
      end
      
      should "set a referrer code, though it shouldn't match the old referrer code" do
        assert @hof_consumers.all? { |c| c.referrer_code.present? }
        assert @hof_consumers.first.referrer_code != @hof_consumer_1.referrer_code
        assert @hof_consumers.second.referrer_code != @hof_consumer_2.referrer_code
      end
      
      should "set the bitly url, though it shouldn't match the old bitly url" do
        assert @hof_consumers.all? { |c| c.referral_url.present? }
        assert @hof_consumers.first.referral_url != @hof_consumer_1.referral_url
        assert @hof_consumers.second.referral_url != @hof_consumer_2.referral_url        
      end
      
      should "copy over the remote record id" do
        assert_equal ["123", "456"], @hof_consumers.map(&:remote_record_id)
      end
      
      should "set the remember token to nil" do
        assert @hof_consumers.all? { |c| c.remember_token.nil? }
      end
      
    end
    
  end
  
end
