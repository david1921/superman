require File.dirname(__FILE__) + "/../../test_helper"

# hydra class PublishingGroups::SilverpopMailingManagementTest

class PublishingGroups::SilverpopMailingManagementTest < ActiveSupport::TestCase

  context "#synchronize_users_that_have_failed_rows" do
    setup do
      FakeWeb.allow_net_connect = false

      @publishing_group = Factory(:publishing_group, :label => "bcbsa")
      @old_publisher = Factory(:publisher, :publishing_group => @publishing_group)
      @new_publisher = Factory(:publisher, :publishing_group => @publishing_group)

      silverpop_session = mock("silverpop_session")
      @silverpop = mock("silverpop") { expects(:open).yields(silverpop_session) }
      Analog::ThirdPartyApi::Silverpop.expects(:new).returns(@silverpop)
    end

    should "synchronize all failed new_silverpop_recipients and silverpop_move_list consumers when no limit is present" do
      consumer_1  = Factory(:consumer, :publisher => @new_publisher)
      consumer_2  = Factory(:consumer, :publisher => @new_publisher)
      consumer_3  = Factory(:consumer, :publisher => @new_publisher)
      consumer_4  = Factory(:consumer, :publisher => @new_publisher)
      consumer_5  = Factory(:consumer, :publisher => @new_publisher)
      consumer_6  = Factory(:consumer, :publisher => @new_publisher)
      consumer_7  = Factory(:consumer, :publisher => @new_publisher)

      recipient_1 = Factory(:new_silverpop_recipient, :consumer => consumer_1, :error_at => Time.zone.now, :success_at => nil)
      recipient_2 = Factory(:new_silverpop_recipient, :consumer => consumer_2, :error_at => Time.zone.now, :success_at => nil)
      recipient_3 = Factory(:new_silverpop_recipient, :consumer => consumer_5, :error_at => nil, :success_at => Time.zone.now + 1.hour)
      recipient_4 = Factory(:new_silverpop_recipient, :consumer => consumer_6, :error_at => nil, :success_at => nil)

      list_move_1 = Factory(:silverpop_list_move, :consumer => consumer_2, :error_at => Time.zone.now,
                      :success_at => nil, :old_publisher => @old_publisher, :new_publisher => @new_publisher,
                      :old_list_identifier => "203210", :new_list_identifier => "239438")
      list_move_2 = Factory(:silverpop_list_move, :consumer => consumer_3, :error_at => Time.zone.now,
                      :success_at => nil, :old_publisher => @old_publisher, :new_publisher => @new_publisher,
                      :old_list_identifier => "203210", :new_list_identifier => "239438")
      list_move_3 = Factory(:silverpop_list_move, :consumer => consumer_4, :error_at => Time.zone.now,
                      :success_at => nil, :old_publisher => @old_publisher, :new_publisher => @new_publisher,
                      :old_list_identifier => "203210", :new_list_identifier => "239438")
      list_move_4 = Factory(:silverpop_list_move, :consumer => consumer_5, :error_at => Time.zone.now,
                      :success_at => Time.zone.now + 1.hour, :old_publisher => @old_publisher, :new_publisher => @new_publisher,
                      :old_list_identifier => "203210", :new_list_identifier => "239438")
      list_move_5 = Factory(:silverpop_list_move, :consumer => consumer_7, :error_at => nil,
                      :success_at => nil, :old_publisher => @old_publisher, :new_publisher => @new_publisher,
                      :old_list_identifier => "203210", :new_list_identifier => "239438")


      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_1, @silverpop).once
      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_2, @silverpop).once
      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_3, @silverpop).once
      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_4, @silverpop).once
      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_5, @silverpop).never
      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_6, @silverpop).once
      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_7, @silverpop).once

      silverpop_items = [recipient_1, recipient_2, recipient_4, list_move_1, list_move_2, list_move_3, list_move_5]

      Timecop.freeze(frozen_time = Time.zone.now) do
        @publishing_group.synchronize_users_that_have_failed_rows
        silverpop_items.each do |item|
          item.reload
          assert_equal frozen_time.to_s, item.success_at.to_s
          assert_equal "Synched with silverpop:synchronize_users_that_have_failed_rows", item.memo
        end
      end
    end

    context "with a limit passed" do
      setup do
        consumer_1  = Factory(:consumer, :publisher => @new_publisher)
        consumer_2  = Factory(:consumer, :publisher => @new_publisher)
        consumer_3  = Factory(:consumer, :publisher => @new_publisher)
        consumer_4  = Factory(:consumer, :publisher => @new_publisher)
        consumer_5  = Factory(:consumer, :publisher => @new_publisher)

        recipient_1 = Factory(:new_silverpop_recipient, :consumer => consumer_1, :error_at => Time.zone.now, :success_at => nil)
        recipient_2 = Factory(:new_silverpop_recipient, :consumer => consumer_2, :error_at => Time.zone.now, :success_at => nil)
        recipient_3 = Factory(:new_silverpop_recipient, :consumer => consumer_3, :error_at => Time.zone.now, :success_at => nil)

        list_move_1 = Factory(:silverpop_list_move, :consumer => consumer_4, :error_at => Time.zone.now,
                        :success_at => nil, :old_publisher => @old_publisher, :new_publisher => @new_publisher,
                        :old_list_identifier => "203210", :new_list_identifier => "239438")
        list_move_2 = Factory(:silverpop_list_move, :consumer => consumer_5, :error_at => Time.zone.now,
                        :success_at => nil, :old_publisher => @old_publisher, :new_publisher => @new_publisher,
                        :old_list_identifier => "203210", :new_list_identifier => "239438")
        @publishing_group.expects(:sync_consumer_with_silverpop).times(3)
      end

      should "only synchronize a limited amount of records if a limit is passed as an integer" do
        @publishing_group.synchronize_users_that_have_failed_rows(3)
      end

      should "only synchronize a limited amount of records if a limit is passed as an string" do
        @publishing_group.synchronize_users_that_have_failed_rows("3")
      end
    end

    should "send an exception to exceptional if a sync fails" do
      consumer_1  = Factory(:consumer, :publisher => @new_publisher)
      consumer_2  = Factory(:consumer, :publisher => @new_publisher)

      recipient = Factory(:new_silverpop_recipient, :consumer => consumer_1, :error_at => Time.zone.now, :success_at => nil)
      list_move = Factory(:silverpop_list_move, :consumer => consumer_2, :error_at => Time.zone.now,
                      :success_at => nil, :old_publisher => @old_publisher, :new_publisher => @new_publisher,
                      :old_list_identifier => "203210", :new_list_identifier => "239438")

      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_1, @silverpop).once.raises(Exception, "test silverpop recipient exception")
      @publishing_group.expects(:sync_consumer_with_silverpop).with(consumer_2, @silverpop).once.raises(Exception, "test silverpop list move exception")
      Exceptional.expects(:handle).twice

      @publishing_group.synchronize_users_that_have_failed_rows
    end
  end

end