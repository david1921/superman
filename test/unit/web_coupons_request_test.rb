require File.dirname(__FILE__) + "/../test_helper"

class WebCouponsRequestTest < ActiveSupport::TestCase
  def test_new_index
    date_time = DateTime.parse("Mar 15, 2010 12:34:56")
    Time.stubs(:now).returns(date_time)
    index = Api2::WebCouponsRequest::Index.new(:publisher => publishers(:sdh_austin), :timestamp_min => date_time - 9876.seconds)

    assert index.valid?, "Should be valid"
    assert_equal publishers(:sdh_austin), index.publisher
    assert_equal DateTime.parse("Mar 15, 2010 12:34:46"), index.timestamp_max
    assert_equal DateTime.parse("Mar 15, 2010 09:50:20"), index.timestamp_min
  end

  def test_index_offers
    advertiser = advertisers(:changos)
    advertiser.offers.destroy_all

    Time.stubs(:now).returns(Time.parse("Mar 15, 2010 12:35:56 UTC"))
    offer_1 = advertiser.offers.create!(:message => "Offer 1")

    Time.stubs(:now).returns(Time.parse("Mar 15, 2010 12:35:56 UTC"))
    offer_2 = advertiser.offers.create!(:message => "Offer 2")
    Time.stubs(:now).returns(Time.parse("Mar 15, 2010 12:35:57 UTC"))
    offer_2.update_attributes! :terms => "New terms"

    advertiser = advertisers(:el_greco)
    advertiser.offers.destroy_all

    Time.stubs(:now).returns(Time.parse("Mar 15, 2010 12:35:56 UTC"))
    offer_3 = advertiser.offers.create!(:message => "Offer 3")
    Time.stubs(:now).returns(Time.parse("Mar 15, 2010 12:35:58 UTC"))
    offer_3.delete!

    Time.stubs(:now).returns(DateTime.parse("Mar 15, 2010 12:36:08"))
    index = Api2::WebCouponsRequest::Index.new(:publisher => publishers(:sdh_austin))
    assert_equal [offer_1, offer_2, offer_3].sort, index.offers.sort

    index = Api2::WebCouponsRequest::Index.new(:publisher => publishers(:sdh_austin), :timestamp_min => DateTime.parse("Mar 15, 2010 12:35:57"))
    assert_equal [offer_2, offer_3].sort, index.offers.sort

    Time.stubs(:now).returns(DateTime.parse("Mar 15, 2010 12:36:07"))
    index = Api2::WebCouponsRequest::Index.new(:publisher => publishers(:sdh_austin))
    assert_equal [offer_1, offer_2].sort, index.offers.sort

    Time.stubs(:now).returns(DateTime.parse("Mar 15, 2010 12:36:06"))
    index = Api2::WebCouponsRequest::Index.new(:publisher => publishers(:sdh_austin))
    assert_equal [offer_1], index.offers

    Time.stubs(:now).returns(DateTime.parse("Mar 15, 2010 12:36:05"))
    index = Api2::WebCouponsRequest::Index.new(:publisher => publishers(:sdh_austin))
    assert_equal [], index.offers
  end

  def test_new_show
    show = Api2::WebCouponsRequest::Show.new(:user => users(:mickey), :id => offers(:changos_buy_two_tacos).to_param)
    assert show.valid?, "Should be valid"
  end

  def test_show_requires_user
    show = Api2::WebCouponsRequest::Show.new(:id => offers(:changos_buy_two_tacos).to_param)
    assert show.invalid?, "Should be invalid"
    assert_match /can\'t be blank/i, show.errors.on(:user)
  end

  def test_show_requires_ids
    show = Api2::WebCouponsRequest::Show.new(:user => users(:mickey), :id => " ")
    assert show.invalid?, "Should be invalid"
    assert_match /must be present/i, show.errors.on(:id)
  end

  def test_show_offers
    advertiser = advertisers(:changos)
    advertiser.offers.destroy_all
    offer_1 = advertiser.offers.create!(:message => "Offer 1")
    offer_2 = advertiser.offers.create!(:message => "Offer 2")

    advertiser = advertisers(:el_greco)
    advertiser.offers.destroy_all
    offer_3 = advertiser.offers.create!(:message => "Offer 3")

    show = Api2::WebCouponsRequest::Show.new(:user => users(:mickey), :id => [offer_1, offer_2, offer_3].map(&:to_param).join(","))
    assert_equal [offer_1, offer_2, offer_3].sort, show.offers.sort

    show = Api2::WebCouponsRequest::Show.new(:user => users(:mickey), :id => [offer_1, offer_2].map(&:to_param).join(","))
    assert_equal [offer_1, offer_2].sort, show.offers.sort
  end

  def test_show_offer_with_inaccessible_offer_id
    advertiser = advertisers(:changos)
    advertiser.offers.destroy_all
    offer_1 = advertiser.offers.create!(:message => "Offer 1")

    advertiser = advertisers(:di_milles)
    advertiser.offers.destroy_all
    offer_2 = advertiser.offers.create!(:message => "Offer 2")

    show = Api2::WebCouponsRequest::Show.new(:user => users(:mickey), :id => [offer_1, offer_2].map(&:to_param))
    assert_raise ActiveRecord::RecordNotFound do
      show.offers
    end
  end

  def test_show_offer_with_syndicated_offer_from_another_publisher
    publisher1 = Factory(:publisher, :offers_available_for_syndication => true, :self_serve => true)
    publisher2 = Factory(:publisher, :self_serve => true)
    user = Factory(:user, :company => publisher2, :allow_offer_syndication_access => true)

    advertiser1 = Factory(:advertiser, :publisher => publisher1)
    advertiser2 = Factory(:advertiser, :publisher => publisher2)

    offer1 = Factory(:offer, :advertiser => advertiser1)
    offer2 = Factory(:offer, :advertiser => advertiser2)

    show = Api2::WebCouponsRequest::Show.new(:user => user, :id => [offer1, offer2].map(&:to_param).join(","))
    assert_same_elements [offer1, offer2], show.offers
  end

  fast_context "#categories_to_xml" do
    setup do
      @categories = ::Api2::WebCouponsRequest::Categories.new
      @categories.publisher = Factory(:publisher)
      @markup = Object.new
      class << @markup
        def categories
          yield if block_given?
        end
      end
    end
    should "be setup" do
      assert_equal 0, @categories.publisher.placed_offers.size
    end
    should "not raise when categories have no parents or there are no categories" do
      assert_nothing_raised do
        @categories.categories_to_xml(@markup)
      end
    end
  end

  fast_context "SyndicatedIndex" do
    setup do
      @publisher1 = Factory(:publisher, :offers_available_for_syndication => false)
      @publisher2 = Factory(:publisher, :offers_available_for_syndication => true)

      @offer1 = Factory(:offer)
      @offer1.place_with(@publisher1)
    end

    fast_context "without syndicated offers" do
      should "return no offers" do
        index = ::Api2::WebCouponsRequest::SyndicatedIndex.new
        assert !index.error
        assert_equal [], index.offers
      end
    end

    fast_context "with syndicated offers" do
      setup do
        Timecop.freeze(1.hour.ago) do
          @offer2 = Factory(:offer)
          @offer2.place_with(@publisher2)
        end

        Timecop.freeze(30.minutes.ago) do
          @offer3 = Factory(:offer)
          @offer3.place_with(@publisher2)
        end
      end

      should "return only syndicatd offers" do
        index = ::Api2::WebCouponsRequest::SyndicatedIndex.new
        assert !index.error
        assert_same_elements [@offer2, @offer3], index.offers
      end

      should "return offers only after timestamp_min" do
        index = ::Api2::WebCouponsRequest::SyndicatedIndex.new(:timestamp_min => 35.minutes.ago)
        assert !index.error
        assert_equal [@offer3], index.offers
      end

      should "correctly set timestamp_min and timestamp_max" do
        date_time = Time.zone.parse("Mar 15, 2010 12:34:56")

        Timecop.freeze(date_time) do
          index = ::Api2::WebCouponsRequest::SyndicatedIndex.new(:timestamp_min => date_time - 9876.seconds)
          assert_equal Time.zone.parse("Mar 15, 2010 12:34:46"), index.timestamp_max
          assert_equal Time.zone.parse("Mar 15, 2010 09:50:20"), index.timestamp_min
        end
      end
    end
  end

end

