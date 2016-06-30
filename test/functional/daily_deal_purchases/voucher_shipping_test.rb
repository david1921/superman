require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::VoucherShippingTest < ActionController::TestCase
  tests DailyDealPurchasesController

  context "with publisher that allows voucher shipping" do
    setup do
      @publisher = Factory(:publisher, :allow_voucher_shipping => true)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    context "#new" do
      should "render the fulfillment options section with a non-travelsavers deal" do
        assert !@daily_deal.travelsavers?
        get :new, :daily_deal_id => @daily_deal.to_param
        assert_response :success
        assert_template "new"
        assert_select "#fulfillment_options" do
          assert_select "h2", "Fulfillment Options"
          assert_select "label[for=daily_deal_purchase_fulfillment_method_email]"
          assert_select "input#daily_deal_purchase_fulfillment_method_email[type=radio][value=email]"
          assert_select "label[for=daily_deal_purchase_fulfillment_method_ship]"
          assert_select "input#daily_deal_purchase_fulfillment_method_ship[type=radio][value=ship]"
          assert_select "fieldset#mailing_address" do
            assert_select "label[for=daily_deal_purchase_mailing_address_attributes_address_line_1]", "Address 1"
            assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_1[type=text]"
            assert_select "label[for=daily_deal_purchase_mailing_address_attributes_address_line_2]", "Address 2"
            assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_2[type=text]"
            assert_select "label[for=daily_deal_purchase_mailing_address_attributes_city]", "City"
            assert_select "input#daily_deal_purchase_mailing_address_attributes_city[type=text]"
            assert_select "label[for=daily_deal_purchase_mailing_address_attributes_state]", "State"
            assert_select "select#daily_deal_purchase_mailing_address_attributes_state"
            assert_select "label[for=daily_deal_purchase_mailing_address_attributes_zip]", "Zip"
            assert_select "input#daily_deal_purchase_mailing_address_attributes_zip[type=text]"
          end
        end
      end

      should "not render the fulfillment options section with a travelsavers deal" do
        ts_deal = Factory :travelsavers_daily_deal
        assert ts_deal.travelsavers?
        get :new, :daily_deal_id => ts_deal.to_param
        assert_response :success
        assert_template "new"
        assert_select "#fulfillment_options", false
      end
    end

    context "#create" do
      context "valid mailing address" do
        should "populate new purchase with mailing address" do
          params = valid_purchase_params(@daily_deal)
          assert_difference "DailyDealPurchase.count" do
            post :create, params
          end
          assert_response :redirect
          ddp = DailyDealPurchase.last
          address = ddp.mailing_address
          assert_not_nil address
          addr_params = params[:daily_deal_purchase][:mailing_address_attributes]
          assert_equal addr_params[:address_line_1], address.address_line_1
          assert_equal addr_params[:address_line_2], address.address_line_2
          assert_equal addr_params[:city], address.city
          assert_equal addr_params[:state], address.state
          assert_equal addr_params[:zip], address.zip
        end
      end

      context "invalid mailing address" do
        should "retain submitted mailing address input values" do
          params = valid_purchase_params(@daily_deal)
          params[:daily_deal_purchase][:mailing_address_attributes][:address_line_1] = nil

          post :create, params

          assert_response :ok
          assert_template 'new'
          assert_select "#fulfillment_options" do
            assert_select "input[type=radio][value=ship][checked]"
            assert_select "fieldset#mailing_address" do
              assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_1[type=text]"

              addr_params = params[:daily_deal_purchase][:mailing_address_attributes]
              assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_2[type=text][value=#{addr_params[:address_line_2]}]"
              assert_select "input#daily_deal_purchase_mailing_address_attributes_city[type=text][value=#{addr_params[:city]}]"
              assert_select "select#daily_deal_purchase_mailing_address_attributes_state option[value=#{addr_params[:state]}][selected]"
              assert_select "input#daily_deal_purchase_mailing_address_attributes_zip[type=text][value=#{addr_params[:zip]}]"
            end
          end
        end
      end

      context "invalid request with voucher emailed, not shipped" do
        should "render mailing address" do
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => {}

          assert_response :ok
          assert_template 'new'
          assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_1[type=text]"
        end
      end
    end

    context "#edit" do
      context "fulfillment method was shipping" do
        should "populate mailing address fields with posted values on error" do
          address = Factory(:address)
          purchase = Factory(:daily_deal_purchase, :mailing_address => address, :daily_deal => @daily_deal, :fulfillment_method => "ship")

          get :edit, :id => purchase.to_param

          assert_response :success
          assert_template 'new'
          assert_select "#fulfillment_options" do
            assert_select "input[type=radio][value=ship]"
            assert_select "fieldset#mailing_address" do
              assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_1[type=text][value=#{address.address_line_1}]"
              assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_2[type=text][value=#{address.address_line_2}]"
              assert_select "input#daily_deal_purchase_mailing_address_attributes_city[type=text][value=#{address.city}]"
              assert_select "select#daily_deal_purchase_mailing_address_attributes_state option[value=#{address.state}][selected]"
              assert_select "input#daily_deal_purchase_mailing_address_attributes_zip[type=text][value=#{address.zip}]"
            end
          end
        end
      end

      context "fulfillment method is not shipping" do
        should "render mailing address inputs" do
          purchase = Factory(:daily_deal_purchase, :daily_deal => @daily_deal, :fulfillment_method => "email")
          get :edit, :id => purchase.to_param

          assert_response :ok
          assert_template 'new'
          assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_1[type=text]"
        end
      end
    end

    context "#update" do
      context "fulfillment method was shipping" do
        should "populate mailing address fields with posted values on error" do
          address = Factory(:address)
          purchase = Factory(:daily_deal_purchase, :mailing_address => address, :daily_deal => @daily_deal, :fulfillment_method => "ship")

          put :update, :id => purchase.to_param, :daily_deal_purchase => {}

          assert_response :success
          assert_template 'new'
          assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_1[type=text][value=#{address.address_line_1}]"
        end
      end

      context "fulfillment method is not shipping" do
        should "render mailing address inputs" do
          purchase = Factory(:daily_deal_purchase, :daily_deal => @daily_deal, :fulfillment_method => "email")
          put :update, :id => purchase.to_param, :daily_deal_purchase => {}

          assert_response :ok
          assert_template 'new'
          assert_select "input#daily_deal_purchase_mailing_address_attributes_address_line_1[type=text]"
        end
      end
    end

    context "#confirm" do
      context "fulfillment method is 'ship'" do
        setup do
          @purchase = Factory.build(:daily_deal_purchase, :daily_deal => @daily_deal)
          @purchase.set_attributes_if_pending(:fulfillment_method => 'ship', :mailing_address_attributes => Factory.attributes_for(:address))
          @purchase.save!
          set_purchase_session(@purchase)

          get :confirm, :id => @purchase.to_param
          assert_response :success
          assert_template 'confirm'
        end

        should "reflect voucher shipping cost in the value line" do
          assert_select "h2.buy_now_proposition", :text => "Buy a $30.00 Value for $18.00 Now", :count => 1
        end

        should "include the voucher shipping amount in the Braintree transaction details" do
          doc = Nokogiri.parse @response.body
          input = doc.search("input#tr_data").first
          assert_not_nil input
          assert_match /#{Regexp.escape("transaction%5Bamount%5D=18.00")}/, input[:value]
        end
      end

      context "fulfillment method is 'email'" do
        setup do
          @purchase = Factory(:daily_deal_purchase, :mailing_address => Factory(:address), :daily_deal => @daily_deal)
          @purchase.set_attributes_if_pending(:fulfillment_method => 'email')
          set_purchase_session(@purchase)

          get :confirm, :id => @purchase.to_param
          assert_response :success
          assert_template 'confirm'
        end

        should "not have any voucher shipping amount in the value line" do
          assert_select "h2.buy_now_proposition", :text => "Buy a $30.00 Value for $15.00 Now", :count => 1
        end

        should "not include the voucher shipping amount in the Braintree transaction details" do
          doc = Nokogiri.parse @response.body
          input = doc.search("input#tr_data").first
          assert_not_nil input
          assert_match /#{Regexp.escape("transaction%5Bamount%5D=15.00")}/, input[:value]
        end
      end
    end
  end

  context "with publisher that doesn't allow shipping vouchers" do
    setup do
      @publisher = Factory(:publisher, :allow_voucher_shipping => false)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    context "#new" do
      should "not render the voucher shipping section" do
        get :new, :daily_deal_id => @daily_deal.to_param
        assert_response :success
        assert_template "new"
        assert_select "#fulfillment_options", 0
      end
    end

    context "#confirm" do
      context "voucher shipping cost when the fulfillment method is 'ship'" do
        should "not be reflected in the value line" do
          purchase = Factory(:daily_deal_purchase, :mailing_address => Factory(:address), :daily_deal => @daily_deal)
          purchase.set_attributes_if_pending(:fulfillment_method => 'ship')
          set_purchase_session(purchase)

          get :confirm, :id => purchase.to_param
          assert_response :success
          assert_template 'confirm'
          assert_select "h2.buy_now_proposition", :text => "Buy a $30.00 Value for $15.00 Now", :count => 1
        end
      end

      context "voucher shipping cost when the fulfillment method is 'email'" do
        should "not be reflected in the value line" do
          purchase = Factory(:daily_deal_purchase, :mailing_address => Factory(:address), :daily_deal => @daily_deal)
          purchase.set_attributes_if_pending(:fulfillment_method => 'email')
          set_purchase_session(purchase)

          get :confirm, :id => purchase.to_param
          assert_response :success
          assert_template 'confirm'
          assert_select "h2.buy_now_proposition", :text => "Buy a $30.00 Value for $15.00 Now", :count => 1
        end
      end
    end
  end

  private

  def valid_purchase_params(daily_deal)
    {
        :daily_deal_id => daily_deal.to_param,
        :daily_deal_purchase => {
            :quantity => 1,
            :gift => 0,
            :fulfillment_method => "ship",
            :mailing_address_attributes => {
                :address_line_1 => '123 Maple St',
                :address_line_2 => 'Unit B',
                :city => 'Portland',
                :state => 'OR',
                :zip => '12345'
            }
        },
        :consumer => {
            :name => "JP",
            :email => "jp@domain.com",
            :password => "monkey",
            :password_confirmation => "monkey",
            :agree_to_terms => "1"
        }
    }
  end
end
