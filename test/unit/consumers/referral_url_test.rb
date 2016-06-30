require File.dirname(__FILE__) + "/../../test_helper"

class Consumers::ReferralUrlTest < ActiveSupport::TestCase
  context "referral urls" do
    setup do
      @publishing_group = Factory(:publishing_group)
      @publisher1 = Factory(:publisher, :publishing_group => @publishing_group)
      @consumer = Factory(:consumer, :publisher => @publisher1)
    end

    context "referral_url" do
      context "when no publisher given" do
        should "return default to referral url for consumer's publisher" do
          assert_equal 0, @consumer.consumer_referral_urls.count
          assert_match %r|^http://bit.ly/|, @consumer.referral_url
          assert_equal 1, @consumer.consumer_referral_urls.count

          consumer_referral_url = @consumer.consumer_referral_urls.first
          assert_equal @consumer.referral_url, consumer_referral_url.bit_ly_url
          assert_equal @publisher1.id, consumer_referral_url.publisher.id
        end

        should "use cached bit_ly_url on successive calls" do
          BitLyGateway.instance.expects(:shorten).once
          assert_equal 0, @consumer.consumer_referral_urls.count
          @referral_url = @consumer.referral_url
          assert_equal @referral_url, @consumer.referral_url
          assert_equal 1, @consumer.consumer_referral_urls.count
        end
      end

      context "publisher given" do
        setup do
          @publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
        end

        should "return referral url for requested publisher" do
          assert_equal 0, @consumer.consumer_referral_urls.count
          assert_match %r|^http://bit.ly/|, @consumer.referral_url(@publisher2)
          assert_equal 1, @consumer.consumer_referral_urls.count

          consumer_referral_url = @consumer.consumer_referral_urls.first
          assert_equal @consumer.referral_url(@publisher2), consumer_referral_url.bit_ly_url
          assert_equal @publisher2.id, consumer_referral_url.publisher.id
        end

        should "use cached bit_ly_url on successive calls" do
          BitLyGateway.instance.expects(:shorten).once
          assert_equal 0, @consumer.consumer_referral_urls.count
          @referral_url = @consumer.referral_url(@publisher2)
          assert_equal @referral_url, @consumer.referral_url(@publisher2)
          assert_equal 1, @consumer.consumer_referral_urls.count
        end
      end
    end

    context "referral_url_for_bit_ly" do
      should "default to consumer's publisher" do
        assert_match %r|/publishers/#{@publisher1.label}/deal-of-the-day\?referral_code=#{@consumer.referrer_code}$|,
          @consumer.referral_url_for_bit_ly
      end

      should "return url for provided publisher" do
        publisher2 = Factory(:publisher, :publishing_group => @publishing_group)
        assert_match %r|/publishers/#{publisher2.label}/deal-of-the-day\?referral_code=#{@consumer.referrer_code}$|,
          @consumer.referral_url_for_bit_ly(publisher2)
      end
    end
  end
end
