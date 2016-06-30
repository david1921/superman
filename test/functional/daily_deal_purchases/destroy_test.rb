require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::DestroyTest < ActionController::TestCase
  tests DailyDealPurchasesController
  include DailyDealPurchasesTestHelper

  test "destroy pending purchase" do
    ddp = Factory(:daily_deal_purchase)
    delete :destroy, :id => ddp.to_param
    assert_redirected_to publisher_cart_path(ddp.publisher.label)
    assert_equal 'The item was removed.', flash[:notice]
    assert_nil DailyDealPurchase.find_by_uuid(ddp.uuid)
  end

  test "destroy non-pending purchase" do
    ddp = Factory(:captured_daily_deal_purchase)
    delete :destroy, :id => ddp.to_param
    assert_redirected_to publisher_cart_path(ddp.publisher.label)
    assert_equal 'The item could not be removed.', flash[:error]
    assert_equal ddp, DailyDealPurchase.find_by_uuid(ddp.uuid)
  end

  test "destroy non-existent purchase" do
    ddp = Factory(:captured_daily_deal_purchase)
    delete :destroy, :publisher_id => ddp.publisher.id, :id => 'non-existent uuid'
    assert_redirected_to publisher_cart_path(ddp.publisher.label)
    assert_equal 'The item could not be removed.', flash[:error]
  end
end
