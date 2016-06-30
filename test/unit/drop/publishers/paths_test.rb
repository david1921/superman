require File.dirname(__FILE__) + "/../../../test_helper"

class Drop::Publishers::PathTest < ActiveSupport::TestCase
  def setup
    @publisher = Factory(:publisher)
    @drop = Drop::Publisher.new(@publisher)
  end

  context "#support_contact_request_path" do
    should "return the support request path" do
      assert_equal "/publishers/#{@publisher.id}/support_contact_requests/new", @drop.support_contact_request_path
    end
  end

end
