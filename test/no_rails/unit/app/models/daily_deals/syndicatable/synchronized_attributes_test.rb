require File.dirname(__FILE__) + "/../../../models_helper"

# hydra class DailyDeals::Syndicatable::SynchronizedAttributesTest

module DailyDeals::Syndicatable
  class SynchronizedAttributesTest < Test::Unit::TestCase

    def setup
      @obj = Object.new
      @obj.extend(DailyDeals::Syndicatable::SynchronizedAttributes)
    end

    context "#update_syndicated_deal_attributes" do
      context "with changes" do
        setup do
          SynchronizedAttributes::ATTRIBUTES_TO_SYNC_WITH_SOURCE.each do |attr|
            @obj.stubs(:"#{attr}").returns("source #{attr}")
          end

          @syndicated_deals = [syndicated_deal_stub, syndicated_deal_stub]
          @obj.stubs(:syndicated_deals).returns(@syndicated_deals)
        end

        should "update the synced attributes of each syndicated deal" do
          @obj.update_syndicated_deal_attributes
        end

        should "flag the syndicated deal as being synced" do
          @obj.update_syndicated_deal_attributes
          @syndicated_deals.each do |deal|
            assert deal.instance_variable_get(:@syncing_with_source)
          end
        end
      end

      context "without changes" do
        setup do
          SynchronizedAttributes::ATTRIBUTES_TO_SYNC_WITH_SOURCE.each do |attr|
            @obj.stubs(:"#{attr}").returns("source #{attr}")
          end

          @syndicated_deals = [no_change_syndicated_deal_stub, no_change_syndicated_deal_stub]
          @obj.stubs(:syndicated_deals).returns(@syndicated_deals)
        end

        should "update the synced attributes of each syndicated deal" do
          @obj.update_syndicated_deal_attributes
        end

      end
    end

    context "#protect_synced_syndicated_deal_attributes" do
      setup do
        @obj.instance_variable_set(:@syncing_with_source, false)
        @obj.stubs(:new_record?).returns(false)
        @obj.stubs(:source).returns(mock('source deal'))
      end

      should "not protect attributes when syncing with source" do
        @obj.instance_variable_set(:@syncing_with_source, true)
        @obj.expects(:errors).never
        @obj.protect_synced_syndicated_deal_attributes
      end

      should "not protect attributes when a new record" do
        @obj.stubs(:new_record?).returns(true)
        @obj.expects(:errors).never
        @obj.protect_synced_syndicated_deal_attributes
      end

      should "not protect attributes unless deal has source" do
        @obj.stubs(:source).returns(nil)
        @obj.expects(:errors).never
        @obj.protect_synced_syndicated_deal_attributes
      end

      should "add an error when not syncing and attribute changed" do
        changes = mock('changes')
        errors = mock('errors')
        SynchronizedAttributes::ATTRIBUTES_TO_SYNC_WITH_SOURCE.each do |attr|
          changes.stubs(:[]).with(attr.to_s).returns(true)
          errors.expects(:add).with(attr, '%{attribute} must be changed in the source deal')
        end
        @obj.stubs(:changes).returns(changes)
        @obj.stubs(:errors).returns(errors)
        @obj.protect_synced_syndicated_deal_attributes
      end
    end

    private

    def syndicated_deal_stub
      syndicated_deal = stub('syndicated deal')
      SynchronizedAttributes::ATTRIBUTES_TO_SYNC_WITH_SOURCE.each do |attr|
        syndicated_deal.expects(:"#{attr}=").with(@obj.send(:"#{attr}"))
        syndicated_deal.stubs(attr)
      end
      syndicated_deal
    end

    def no_change_syndicated_deal_stub
      syndicated_deal = stub('syndicated deal')
      SynchronizedAttributes::ATTRIBUTES_TO_SYNC_WITH_SOURCE.each do |attr|
        syndicated_deal.expects(:"#{attr}=").with(@obj.send(:"#{attr}")).never
        syndicated_deal.stubs(attr).returns("source #{attr}")
      end
      syndicated_deal
    end
  end
end