require File.dirname(__FILE__) + "/../test_helper"

class ConsumerDealRelevancyScoreTest < ActiveSupport::TestCase

  context "validation" do

    setup do
      @consumer = Factory(:consumer)
      @daily_deal = Factory(:daily_deal)
    end

    should "fail with missing daily deal" do
      score = ConsumerDealRelevancyScore.new(:consumer => @consumer, :relevancy_score => 10)
      assert score.invalid?, "score should be invalid"
      assert_equal "Daily deal can't be blank", score.errors.on(:daily_deal), "should have errors on :daily_deal"
    end

    should "fail with missing consumer" do
      score = ConsumerDealRelevancyScore.new(:daily_deal => @daily_deal, :relevancy_score => 10)
      assert score.invalid?, "score should be invalid"
      assert_equal "Consumer can't be blank", score.errors.on(:consumer), "should have errors on :consumer"
    end

    should "fail with missing relevancy_score" do
      score = ConsumerDealRelevancyScore.new(:daily_deal => @daily_deal, :consumer => @consumer)
      assert score.invalid?, "score should be invalid"
      assert_equal "Relevancy score can't be blank", score.errors.on(:relevancy_score), "should have errors on :relevancy_score"
    end

    should "fail with relevancy score less than 0" do
      score = ConsumerDealRelevancyScore.new(:daily_deal => @daily_deal, :consumer => @consumer, :relevancy_score => -1)
      assert score.invalid?, "score should be invalid"
      assert_equal "Relevancy score must be between 0 and 100", score.errors.on(:relevancy_score), "should have errors on :relevancy_score"
    end

    should "fail with relevancy score greater than 100" do
      score = ConsumerDealRelevancyScore.new(:daily_deal => @daily_deal, :consumer => @consumer, :relevancy_score => 101)
      assert score.invalid?, "score should be invalid"
      assert_equal "Relevancy score must be between 0 and 100", score.errors.on(:relevancy_score), "should have errors on :relevancy_score"
    end

  end
end
