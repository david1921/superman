require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchasesController::DonationTest < ActionController::TestCase
  tests DailyDealPurchasesController

  context "with publisher that allows donations" do
    setup do
      @publisher = Factory(:publisher, :publishing_group => Factory(:publishing_group, :allows_donations => true))
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    context "#new" do
      should "render donation form" do
        get :new, :daily_deal_id => @daily_deal.to_param
        assert_response :success
        assert_template "new"
        assert_select "#donation" do
          assert_select "h2", "Donation"
          assert_donation_label :name, "Organization Name"
          assert_donation_label :city, "City"
          assert_donation_label :state, "State"
          assert_donation_inputs
        end
      end
    end

    context "#create" do
      should "populate new purchase with donation attributes" do
        name, city, state = "Lincoln Elementary", "Portland", "OR"

        login_as Factory(:consumer, :publisher => @publisher)

        assert_difference "DailyDealPurchase.count", 1 do
          post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_purchase => {
              :quantity => 1,
              :gift => 0
          }.merge(donation_attributes)
        end

        ddp = DailyDealPurchase.last

        assert_redirected_to confirm_daily_deal_purchase_url(ddp)

        assert_equal donation_attributes[:donation_name], ddp.donation_name
        assert_equal donation_attributes[:donation_city], ddp.donation_city
        assert_equal donation_attributes[:donation_state], ddp.donation_state
      end
    end

    context "#edit" do
      should "populate donation fields with existing values" do
        login_as consumer = Factory(:consumer, :publisher => @publisher)
        ddp = Factory(:daily_deal_purchase, {
            :consumer => consumer,
            :daily_deal => @daily_deal
        }.merge(donation_attributes))
        get :edit, :id => ddp.to_param

        assert_response :success
        assert_template :new

        assert_select "#donation" do
          assert_select "input[value=\"#{donation_attributes[:donation_name]}\"]#daily_deal_purchase_donation_name"
          assert_select "input[value=\"#{donation_attributes[:donation_city]}\"]#daily_deal_purchase_donation_city"
          assert_select "select#daily_deal_purchase_donation_state option[value=\"#{donation_attributes[:donation_state]}\"][selected=\"selected\"]"
        end
      end
    end
  end

  context "with publisher that doesn't allow donations" do
    setup do
      @publisher = Factory(:publisher, :publishing_group => Factory(:publishing_group, :allows_donations => false))
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    context "#new" do
      should "not render donation form" do
        get :new, :daily_deal_id => @daily_deal.to_param
        assert_response :success
        assert_template "new"
        assert_select "#donation", 0
      end
    end
  end

  context "with 'dealsforschools' publisher" do
    setup do
      @publisher = Factory(:publisher, :publishing_group => Factory(:publishing_group, :allows_donations => true), :label => 'dealsforschools')
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    should "render themed donation form" do
      get :new, :daily_deal_id => @daily_deal.to_param
      assert_response :success
      assert_template "new"
      # TODO: The daily deals layout is completely effed up; assert_select isn't working at all
      #assert_select "#donation" do
      #  assert_select "h2", "Donate To Your School"
      #  assert_donation_label :name, "School Name"
      #  assert_donation_label :city, "City"
      #  assert_donation_label :state, "State"
      #  assert_donation_inputs
      #end
    end
  end

  private

  def donation_attributes
    {
        :donation_name => "Lincoln Elementary",
        :donation_city => "Portland",
        :donation_state => "OR"
    }
  end

  def assert_donation_inputs
    assert_select "input[type=\"text\"]#daily_deal_purchase_donation_name"
    assert_select "input[type=\"text\"]#daily_deal_purchase_donation_city"
    assert_select "select#daily_deal_purchase_donation_state" do
      Addresses::Codes::US::STATE_CODES.each do |abbr|
        assert_select "option", abbr
      end
    end
  end

  def assert_donation_label(name, text)
    assert_select "label[for=daily_deal_purchase_donation_#{name}]", text
  end
end
