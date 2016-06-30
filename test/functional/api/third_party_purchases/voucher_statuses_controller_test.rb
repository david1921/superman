require File.dirname(__FILE__) + "/../../../test_helper"

class Api::ThirdPartyPurchases::VoucherStatusesControllerTest < ActionController::TestCase
  def setup
    ssl_on
    login_with_basic_auth Factory(:user)
  end

  def teardown
    ssl_off
  end

  context "#index" do
    should "render the index xml" do
      get :index
      assert_response :ok
      assert_template 'index.xml'
    end
  end

  context "#create" do
    should "update the certificate statuses" do
      certs = ['1234', '5678', '3456'].collect{|x| Factory(:daily_deal_certificate, :serial_number => x)}
      @request.env['RAW_POST_DATA'] = <<EOF
<voucher_statuses>
  <voucher_status serial_number='1234'>redeemed</voucher_status>
  <voucher_status serial_number='5678'>voided</voucher_status>
  <voucher_status serial_number='3456'>refunded</voucher_status>
</voucher_statuses>"
EOF
      post :create
      assert_equal 'redeemed', certs[0].reload.status
      assert_equal 'voided', certs[1].reload.status
      assert_equal 'refunded', certs[2].reload.status
    end

    should "render index.xml" do
      post :create
      assert_response :ok
      assert_template 'index.xml'
    end
  end
end
