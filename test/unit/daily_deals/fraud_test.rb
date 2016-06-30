require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::FraudTest

module DailyDeals
  class FraudTest < ActiveSupport::TestCase
    context "regenerate_suspected_frauds" do
      setup do
        Timecop.freeze Time.zone.parse("2011-12-14 12:34:56") do
          publisher = Factory(:publisher)
          Factory(:daily_deal, :publisher => publisher, :start_at => Time.zone.now - 2.day, :hide_at => Time.zone.now - 1.day).instance_eval do |dd|
            [
              ["James Salyer","laremp@hotmail.com","24.24.151.107", "0000"],
              ["Ahn Nguyen","poipop001@yahoo.com","75.51.172.217", "0001"],
              ["mula mula","musketeer728@yahoo.com","69.104.164.39", "0002"],
              ["Gretcha Nguyen","wngan16@fastmail.fm","76.231.193.252", "0003"],
              ["tong wan","kwokleeinhk+061@gmail.com","70.239.248.182", "0004"]
            ].each do |name, email, ip_address, last_4|
              consumer = Factory(:consumer, :publisher => publisher, :first_name => name.split.first, :last_name => name.split.second, :email => email)
              ddp = Factory(:captured_daily_deal_purchase, :daily_deal => dd, :consumer => consumer, :ip_address => ip_address)
              ddp.daily_deal_payment.update_attributes!(:credit_card_last_4 => last_4)
            end
          end
          @daily_deal = Factory(:daily_deal, :publisher => publisher, :start_at => Time.zone.now, :hide_at => Time.zone.now + 1.day)
          @daily_deal_purchases = []
          [
            ["Welbert lee","welbert+132@gmail.com","71.143.155.219", "0001"],
            ["First Last","13@sales.s5.com","76.93.35.39", "0002"],
            ["Thomas Caragan","tcaragan@powerdirect.net","98.189.42.47", "0003"],
            ["First Last","3@sales.s5.com","76.93.35.39", "0004"],
            ["Welbert lee","welbert+131@gmail.com","71.143.155.219", "0005"],
            ["Welbert lee","welbert+130@gmail.com","71.143.155.219", "0006"],
            ["Kathy Phi","asianboy.a@gmail.com","98.154.219.240", "0007"],
            ["Vito Lee","GreenWins1989+25@gmail.com","71.143.155.219", "0008"],
            ["Kathy Phi","a.sianboy.a@gmail.com","98.154.219.240", "0009"],
            ["Harriet Gordon","Harrietgordon@aol.com","75.84.216.192", "0010"],
            ["Stephanie Gordon","Sbgordon1@aol.com","75.84.216.192", "0011"],
            ["Jason Choi","jchoi@powerdirect.net","98.189.42.47", "0012"],
            ["Vito Lee","GreenWins1989+21@gmail.com","71.143.155.219", "0013"]
          ].each do |name, email, ip_address, last_4|
            consumer = Factory(:consumer, :publisher => publisher, :first_name => name.split.first, :last_name => name.split.second, :email => email)
            ddp = Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :consumer => consumer, :ip_address => ip_address)
            ddp.daily_deal_payment.update_attributes!(:credit_card_last_4 => last_4)
            @daily_deal_purchases << ddp
          end
        end

      end
      
      should "insert all purchases when the threshold is set to 0.0" do
        assert_difference 'SuspectedFraud.for_deal(@daily_deal).count', @daily_deal_purchases.size do
          @daily_deal.regenerate_suspected_frauds(0.0, 5)
        end
        assert_same_elements @daily_deal_purchases.map(&:id), SuspectedFraud.for_deal(@daily_deal).map(&:suspect_daily_deal_purchase_id)
      end

      should "insert no purchases when the threshold is set to 1.0" do
        assert_no_difference 'SuspectedFraud.for_deal(@daily_deal).count' do
          @daily_deal.regenerate_suspected_frauds(1.0, 5)
        end
      end

      should "insert some purchases when the threshold is set to 0.7" do
        @daily_deal.regenerate_suspected_frauds(0.7, 5)
        expected_frauds = [
          { :score=>0.752, :id1=>@daily_deal_purchases[3].id, :id2=>@daily_deal_purchases[1].id },
          { :score=>0.702, :id1=>@daily_deal_purchases[4].id, :id2=>@daily_deal_purchases[0].id },
          { :score=>0.740, :id1=>@daily_deal_purchases[8].id, :id2=>@daily_deal_purchases[6].id }                           
        ]        
        suspected_frauds = SuspectedFraud.for_deal(@daily_deal).all(:order => "suspect_daily_deal_purchase_id")
        
        assert_equal expected_frauds.size, suspected_frauds.size
        expected_frauds.each_with_index do |expected, index|
          suspected = suspected_frauds[index]
          assert_equal expected[:id1], suspected.suspect_daily_deal_purchase_id
          assert_equal expected[:id2], suspected.matched_daily_deal_purchase_id
          assert_in_delta expected[:score], suspected.score, 0.001
        end
      end
    end
  end
end
