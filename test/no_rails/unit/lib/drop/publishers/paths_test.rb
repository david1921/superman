require File.dirname(__FILE__) + "/../../drop_helper"
require 'liquid/drop'

class Drop::Publishers::PathsTest < Test::Unit::TestCase
  def setup
    @obj = Object.new.extend(Drop::Publishers::Paths)
    @publisher = mock('publisher')
    @obj.stubs(:publisher).returns(@publisher)
  end

  context "#support_contact_request_path" do
    should "return the support request path" do
      path = mock('support request path')
      @obj.expects(:new_publisher_support_contact_request_path).with(@obj.publisher).returns(path)
      assert_equal path, @obj.support_contact_request_path
    end
  end
end
