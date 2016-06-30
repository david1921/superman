require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class DailyDeals::SynchronizedAttributesTest

module DailyDeals

  class SynchronizedAttributesTest < ActiveSupport::TestCase

    def setup
      @deal = Factory(:distributed_daily_deal)
    end

    # context "translation attributes" do
    #   should "synchronize all the translation attributes" do
    #     synched_translation_attrs = DailyDeals::Syndicatable::SynchronizedAttributes::ATTRIBUTES_TO_SYNC_WITH_SOURCE & DailyDeal.translated_attribute_names
    #     assert_equal  DailyDeal.translated_attribute_names, synched_translation_attrs,  "We should add these attributes: #{(DailyDeal.translated_attribute_names - synched_translation_attrs).map(&:to_s).join(',')}"
    #   end
    # end

    context "#update_syndicated_deal_attributes" do
      should "update a synchronized attribute when the source changes" do\
        qty = @deal.source.quantity + 100
        @deal.source.update_attributes!(:quantity => qty)
        assert_equal qty, @deal.source.quantity
        assert_equal qty, DailyDeal.find(@deal.id)[:quantity]
      end
    end

    context "#protect_synced_syndicated_deal_attributes" do
      should "add an error when a synchronized attribute is not changed in the source deal" do
        @deal.quantity = @deal.quantity + 1
        assert !@deal.valid?
        assert_equal 'Quantity must be changed in the source deal', @deal.errors[:quantity]
      end

      should "not protect attributes when a new record" do
        deal = Factory.build(:distributed_daily_deal)
        deal.quantity = deal.quantity + 10
        assert_not_nil deal.changes['quantity']
        assert deal.valid?
      end

      should "not protect attributes when syncing with a source deal" do
        deal = @deal.source
        deal.quantity = deal.quantity + 10
        assert_not_nil deal.changes['quantity']
        assert deal.valid?
      end

      should "not protect attributes for a non-syndicated deal" do
        deal = @deal.source
        deal.quantity = deal.quantity + 10
        assert_not_nil deal.changes['quantity']
        assert deal.valid?
      end
    end
    
    context "#certificates_to_generate_per_unit_quantity" do
      
      should "be initialized from the source deal at time of syndication" do
        publisher = Factory :publisher
        source_deal = Factory :daily_deal, :available_for_syndication => true, :quantity => 300, :certificates_to_generate_per_unit_quantity => 3
        syndicated_deal = syndicate(source_deal, publisher)
        assert_equal 3, syndicated_deal.certificates_to_generate_per_unit_quantity
      end
      
      should "be synchronized with the source deal" do
        assert_equal 1, @deal.source.certificates_to_generate_per_unit_quantity
        assert_equal 1, @deal.certificates_to_generate_per_unit_quantity
        @deal.source.update_attributes! :certificates_to_generate_per_unit_quantity => 2
        @deal.reload
        assert_equal 2, @deal.certificates_to_generate_per_unit_quantity
      end
      
      should "be invalid when modified on a syndicated deal" do
        assert @deal.valid?
        @deal.certificates_to_generate_per_unit_quantity = 2
        assert @deal.invalid?
        assert_equal "Certificates to generate per unit quantity must be changed in the source deal", @deal.errors.on(:certificates_to_generate_per_unit_quantity)
      end
      
    end
    
  end

end
