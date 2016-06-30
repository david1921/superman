require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Consumers::AfterUpdateTest
module Consumers
  class AfterUpdateTest < ActiveSupport::TestCase

     context "executing after publisher changed strategy" do
       should "default strategy" do
         publisher1 = Factory(:publisher)
         publisher2 = Factory(:publisher)
         consumer = Factory(:consumer, :publisher => publisher1)
         consumer.publisher = publisher2
         consumer.save!
         consumer.reload
         assert_equal publisher2, consumer.publisher
       end
     end

     context "executing update_silverpop strategy" do
       setup do
         Consumers::AfterUpdateStrategy::UpdateSilverpop.any_instance.stubs(:enqueue_job)
         @publishing_group = Factory(:publishing_group, :consumer_after_update_strategy => "update_silverpop")
         @publisher1 = Factory(:publisher, :publishing_group => @publishing_group, :silverpop_list_identifier => "1234")
         @publisher2 = Factory(:publisher, :publishing_group => @publishing_group, :silverpop_list_identifier => "4567")
         @consumer = Factory(:consumer, :publisher => @publisher1, :email => "foobar@yahoo.com")
       end

       should "create SilverpopListMove if publisher changed but email did not" do
         @consumer.publisher = @publisher2
         @consumer.save!
         @consumer.reload
         assert_equal @publisher2, @consumer.publisher
         silverpop_list_move = SilverpopListMove.find_by_consumer_id(@consumer.id)
         assert_not_nil silverpop_list_move
         assert_equal @publisher1, silverpop_list_move.old_publisher
         assert_equal @publisher2, silverpop_list_move.new_publisher
         assert_equal "1234", silverpop_list_move.old_list_identifier
         assert_equal "4567", silverpop_list_move.new_list_identifier
       end

       should "create NewSilverpopRecipient if email changed" do
         @consumer.email = "foobar_new@yahoo.com"
         @consumer.save!
         @consumer.reload
         new_silverpop_recipient = NewSilverpopRecipient.find_by_consumer_id(@consumer.id)
         assert_not_nil new_silverpop_recipient
         assert_equal "foobar@yahoo.com", new_silverpop_recipient.old_email
       end

     end

  end
end

