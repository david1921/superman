require File.dirname(__FILE__) + "/../../../test_helper"

class ReassignSubscribersFromGenericPublisherJob < ActiveSupport::TestCase
  context "when some subscribers need reassigning and other do not" do
    setup do
      @entertainment_publishing_group = Factory :publishing_group, :label => 'entertainment'
      @entertainment = Factory :publisher, :label => 'entertainment'
      
      @subscriber1, @correct_publisher1 = setup_subscriber '12345', '12345'
      @subscriber2, @correct_publisher2 = setup_subscriber '23456', '23456'
      @subscriber3, extraneous_publisher = setup_subscriber '34567', '45678'

      assert_subscriber_has_correct_publisher [@subscriber1, @subscriber2, @subscriber3], @entertainment
    end
    should 'reassign suscribers needing to be reassigned and NOT reassign suscribers NOT needing to be reassigned upon real run' do
      Jobs::ReassignSubscribersFromGenericPublisherJob.perform false, true
      # should reassign suscribers not needing to be reassigned
      assert_subscriber_has_correct_publisher @subscriber1, @correct_publisher1
      assert_subscriber_has_correct_publisher @subscriber2, @correct_publisher2      
      # should not reassign suscribers not needing to be reassigned
      assert_subscriber_has_correct_publisher @subscriber3, @entertainment    
    end
    should 'not reassign any subscribers upon dry run' do
      Jobs::ReassignSubscribersFromGenericPublisherJob.perform true, true
      assert_subscriber_has_correct_publisher [@subscriber1, @subscriber2, @subscriber3], @entertainment
    end
  end

  def setup_subscriber(subscriber_zip_code, publisher_zip_code)
    subscriber = Factory :subscriber, :publisher => @entertainment, :zip_code => subscriber_zip_code
    publisher = Factory :publisher, :publishing_group => @entertainment_publishing_group
    publisher.publisher_zip_codes << PublisherZipCode.new(:zip_code => publisher_zip_code)
    [subscriber, publisher]
  end

  def assert_subscriber_has_correct_publisher(subscriber, publisher)
    subscribers = subscriber.respond_to?(:each) ? subscriber : [subscriber]
    subscribers.each do |sub|
      sub.reload
      assert_equal sub.publisher, publisher
    end
  end
end