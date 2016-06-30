require File.dirname(__FILE__) + "/../../models_helper"

class DailyDeals::CoreTest < Test::Unit::TestCase
  def setup
    @deal = stub('daily deal').extend(DailyDeals::Core::InstanceMethods)
  end

  context "#bar_code_symbology" do
    setup do
      formats = [['foo', 6], ['128B', 7], ['bar', 8]]
      @deal.class.stubs(:allowed_bar_code_encoding_formats).returns(formats)
    end

    should "return the symbology of the encoding format" do
      @deal.stubs(:bar_code_encoding_format).returns(7)
      assert_equal '128B', @deal.bar_code_symbology
    end

    should "return nil with an unknown encoding format" do
      @deal.stubs(:bar_code_encoding_format).returns(5)
      assert_nil @deal.bar_code_symbology
    end
  end

  context "#pay_using?" do
    should "return true if payment method matches source deal publisher's payment method" do
      @deal.stubs(:payment_method).returns("travelsavers")
      assert @deal.pay_using?(:travelsavers)
    end
  end

  context "#payment_method" do
    context "deal is syndicated" do
      setup do
        @deal.stubs(:syndicated?).returns(true)
        @source_publisher = stub(:source_publisher)
        @deal.stubs(:source_publisher).returns(@source_publisher)
      end

      context "source deal's publisher uses travelsavers" do
        setup do
          @source_publisher.stubs(:pay_using?).with(:travelsavers).returns(true)
        end

        should "return 'travelsavers'" do
          assert_equal "travelsavers", @deal.payment_method
        end
      end

      context "source publisher does not use travelsavers" do
        setup do
          @source_publisher.stubs(:pay_using?).with(:travelsavers).returns(false)
          @publisher = stubs(:publisher).tap do |p|
            p.stubs(:payment_method).returns("credit")
          end
          @deal.stubs(:publisher).returns(@publisher)
        end

        should "return publisher's payment method" do
          assert_equal "credit", @deal.payment_method
        end
      end
    end

    context "not distributed deal" do
      setup do
        @deal.stubs(:syndicated?).returns(false)
        @publisher = stubs(:publisher).tap do |p|
          p.stubs(:payment_method).returns("credit")
        end
        @deal.stubs(:publisher).returns(@publisher)
      end

      should "return publisher's payment method" do
        assert_equal "credit", @deal.payment_method
      end
    end
  end
end