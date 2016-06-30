require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::FraudTest

class Publishers::FraudTest < ActiveSupport::TestCase
  context "a publisher having several potentially fraudulent daily deal purchases" do
    setup do
      @publisher = Factory(:publisher)
      show_at, hide_at = Time.zone.local(2012, 1, 1, 0, 0, 0), Time.zone.local(2012, 1, 1, 23, 55, 0)
      Factory(:daily_deal, :publisher => @publisher, :start_at => show_at, :hide_at => hide_at).instance_eval do |deal|
        [
          ["James Salyer","laremp@hotmail.com","24.24.151.107", "0000"],
          ["Ahn Nguyen","poipop001@yahoo.com","75.51.172.217", "0001"],
          ["mula mula","musketeer728@yahoo.com","69.104.164.39", "0002"],
          ["Gretcha Nguyen","wngan16@fastmail.fm","76.231.193.252", "0003"],
          ["tong wan","kwokleeinhk+061@gmail.com","70.239.248.182", "0004"]
        ].each_with_index do |data, index|
          name, email, ip_address, last_4 = data
          Timecop.freeze Time.zone.local(2012, 1, 1, 12, index, 34) do
            consumer = Factory(:consumer, :publisher => @publisher, :first_name => name.split.first, :last_name => name.split.second, :email => email)
            purchase = Factory(:captured_daily_deal_purchase, :daily_deal => deal, :consumer => consumer, :ip_address => ip_address)
            purchase.daily_deal_payment.update_attributes!(:credit_card_last_4 => last_4)
          end
        end
      end
      show_at, hide_at = Time.zone.local(2012, 1, 2, 0, 0, 0), Time.zone.local(2012, 1, 2, 23, 55, 0)
      daily_deal = Factory(:daily_deal, :publisher => @publisher, :start_at => show_at, :hide_at => hide_at)
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
      ].each_with_index do |data, index|
        name, email, ip_address, last_4 = data
        Timecop.freeze Time.zone.local(2012, 1, 2, 12, index, 56) do
          consumer = Factory(:consumer, :publisher => @publisher, :first_name => name.split.first, :last_name => name.split.second, :email => email)
          purchase = Factory(:captured_daily_deal_purchase, :daily_deal => daily_deal, :consumer => consumer, :ip_address => ip_address)
          purchase.daily_deal_payment.update_attributes!(:credit_card_last_4 => last_4)
          @daily_deal_purchases << purchase
        end
      end
    end
    
    should "insert all captured purchases within the increment as suspected frauds when the threshold is set to 0.0" do
      assert_difference 'SuspectedFraud.count', @daily_deal_purchases.size do
        last_timestamp = Time.zone.local(2012, 1, 2, 0, 0, 0)
        this_timestamp = Time.zone.local(2012, 1, 3, 0, 0, 0)
        @publisher.generate_suspected_frauds_for_increment(last_timestamp, this_timestamp, 0.0, 5)
      end
      assert_same_elements @daily_deal_purchases.map(&:id), SuspectedFraud.all.map(&:suspect_daily_deal_purchase_id)
    end

    should "insert no purchases as suspected frauds when the threshold is set to 1.0" do
      assert_no_difference 'SuspectedFraud.count' do
        last_timestamp = Time.zone.local(2012, 1, 2, 0, 0, 0)
        this_timestamp = Time.zone.local(2012, 1, 3, 0, 0, 0)
        @publisher.generate_suspected_frauds_for_increment(last_timestamp, this_timestamp, 1.0, 5)
      end
    end

    should "insert some purchases within the increment as suspected frauds when the threshold is set to 0.6" do
      last_timestamp = Time.zone.local(2012, 1, 2, 0, 0, 0)
      this_timestamp = Time.zone.local(2012, 1, 3, 0, 0, 0)
      @publisher.generate_suspected_frauds_for_increment(last_timestamp, this_timestamp, 0.6, 5)

      expected_frauds = [
        { :score=>0.699, :suspect=>@daily_deal_purchases[3].id, :matched=>@daily_deal_purchases[1].id },
        { :score=>0.648, :suspect=>@daily_deal_purchases[4].id, :matched=>@daily_deal_purchases[0].id },
        { :score=>0.656, :suspect=>@daily_deal_purchases[5].id, :matched=>@daily_deal_purchases[4].id },
        { :score=>0.684, :suspect=>@daily_deal_purchases[8].id, :matched=>@daily_deal_purchases[6].id }                           
      ]        
      suspected_frauds = SuspectedFraud.all(:order => "suspect_daily_deal_purchase_id")
      
      assert_equal expected_frauds.size, suspected_frauds.size
      expected_frauds.each_with_index do |expected, index|
        suspected = suspected_frauds[index]
        assert_equal expected[:suspect], suspected.suspect_daily_deal_purchase_id
        assert_equal expected[:matched], suspected.matched_daily_deal_purchase_id
        assert_in_delta expected[:score], suspected.score, 0.001
      end
    end
    
    should "create a job entry in generate_suspected_frauds when there is an existing job entry" do
      key = "publisher:#{@publisher.label}:generate_suspected_frauds"
      last_timestamp = Time.zone.local(2012, 1, 2, 0, 0, 0)
      this_timestamp = Time.zone.local(2012, 1, 3, 0, 0, 0)
      Job.create!(:key => key, :increment_timestamp => last_timestamp, :started_at => last_timestamp, :finished_at => last_timestamp + 5.minutes)

      Timecop.freeze this_timestamp do
        assert_difference 'Job.count' do
          @publisher.generate_suspected_frauds(0.6, 5)
        end
      end
      job = Job.last
      assert_equal key, job.key
      assert_equal this_timestamp, job.increment_timestamp

      assert_equal 4, SuspectedFraud.count
      SuspectedFraud.all.each { |suspected_fraud| assert_equal job, suspected_fraud.job }
    end

    should "create a job entry in generate_suspected_frauds when there is no existing job entry" do
      this_timestamp = Time.zone.local(2012, 1, 3, 0, 0, 0)

      Timecop.freeze this_timestamp do
        assert_difference 'Job.count' do
          @publisher.generate_suspected_frauds(0.6, 5)
        end
      end
      job = Job.last
      assert_equal "publisher:#{@publisher.label}:generate_suspected_frauds", job.key
      assert_equal this_timestamp, job.increment_timestamp

      assert_equal 4, SuspectedFraud.count
      SuspectedFraud.all.each { |suspected_fraud| assert_equal job, suspected_fraud.job }
    end

    should "pass the suspected_fraud instances created within the last job to the block" do
      key = "publisher:#{@publisher.label}:generate_suspected_frauds"
      
      jobs = []
      timestamp_1 = Time.zone.local(2012, 1, 2, 0, 0, 0)
      jobs << Job.create!(:key => key, :increment_timestamp => timestamp_1, :started_at => timestamp_1, :finished_at => timestamp_1 + 5.minutes)
      timestamp_2 = Time.zone.local(2012, 1, 3, 0, 0, 0)
      jobs << Job.create!(:key => key, :increment_timestamp => timestamp_2, :started_at => timestamp_2, :finished_at => timestamp_2 + 5.minutes)
      
      daily_deal = Factory(:daily_deal, :publisher => @publisher)
      matched = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
      suspected_frauds = []
      
      create_suspected_fraud = lambda do |timestamp, score, job|
        rec = nil
        Timecop.freeze(timestamp) {
          suspect = Factory(:daily_deal_purchase, :daily_deal => daily_deal)
          rec = SuspectedFraud.create!(:suspect_daily_deal_purchase => suspect, :matched_daily_deal_purchase => matched, :score => score, :job => job)
        }
        rec
      end
      suspected_frauds << create_suspected_fraud.call(timestamp_1 + 0.seconds, 0.6, jobs[0])
      suspected_frauds << create_suspected_fraud.call(timestamp_1 + 1.seconds, 0.7, jobs[0])
      suspected_frauds << create_suspected_fraud.call(timestamp_2 + 0.seconds, 0.7, jobs[1])
      suspected_frauds << create_suspected_fraud.call(timestamp_2 + 1.seconds, 0.8, jobs[1])
      suspected_frauds << create_suspected_fraud.call(timestamp_2 + 2.seconds, 0.6, jobs[1])
      
      last_job_frauds = [].tap do |array|
        @publisher.with_suspected_frauds_from_last_job { |suspected_fraud| array << suspected_fraud }
      end
      assert_equal 3, last_job_frauds.size
      assert_equal suspected_frauds[3], last_job_frauds[0]
      assert_equal suspected_frauds[2], last_job_frauds[1]
      assert_equal suspected_frauds[4], last_job_frauds[2]
    end
  end
end
