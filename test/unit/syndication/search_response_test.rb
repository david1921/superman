require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Syndication::SearchResponseTest

class Syndication::SearchResponseTest < ActiveSupport::TestCase

  context "new" do

    context "with deals" do

      setup do
        @deals = [Factory(:daily_deal)]
        @response = Syndication::SearchResponse.new( :deals => @deals )
      end

      should "return a Syndication::SearchResponse" do
        assert @response.is_a?( Syndication::SearchResponse )
      end

      should "assign the deals" do
        assert_equal @deals, @response.deals
      end
      
      should "indicate results" do
        assert @response.results?
      end
      
    end
    
    context "without deals" do

      setup do
        @deals = []
        @response = Syndication::SearchResponse.new( :deals => @deals )
      end

      should "return a Syndication::SearchResponse" do
        assert @response.is_a?( Syndication::SearchResponse )
      end

      should "assign the deals" do
        assert_equal @deals, @response.deals
      end
      
      should "indicate no results" do
        assert !@response.results?
      end
      
    end
  end

end
