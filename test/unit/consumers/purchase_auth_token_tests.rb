require File.dirname(__FILE__) + "/../../test_helper"

class Consumers::PurcahseAuthTokenTests < ActiveSupport::TestCase
  context 'when creating a consumer' do
    setup do
      @consumer = Factory.create :consumer
    end
    should 'have set purchase auth token' do
      assert @consumer.purchase_auth_token.present?
    end
  end
end