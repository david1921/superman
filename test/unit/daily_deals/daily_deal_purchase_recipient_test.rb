require File.dirname(__FILE__) + "/../../test_helper"

class DailyDealPurchaseRecipientTest < ActiveSupport::TestCase
  test "create" do
    ddp = Factory(:daily_deal_purchase)
    recipient = ddp.recipients.create({
      :name => "Steve Man",
      :address_line_1 => "123 Alberta St",
      :address_line_2 => "Room 4",
      :city => "Portland",
      :state => "OR",
      :zip => "97211"
    })
    assert_not_nil recipient, "Should hace created a recipient"
    assert_equal "Steve Man", recipient.name
    assert_equal "123 Alberta St", recipient.address_line_1
    assert_equal "Room 4", recipient.address_line_2
    assert_equal "Portland", recipient.city
    assert_equal "OR", recipient.state
    assert_equal "97211", recipient.zip
  end

  test "create with invalid country" do
    country = Country.new(:code => "F", :name => "Foo")
    ddp = Factory(:daily_deal_purchase)
    recipient = ddp.recipients.create({
      :name => "Steve Guy",
      :address_line_1 => "123 Alberta St",
      :address_line_2 => "Room 4",
      :city => "Portland",
      :state => "OR",
      :zip => "97211",
      :country => country
    })
    assert_equal false, recipient.valid?
    assert recipient.errors.on(:country)
  end

  test "create without name" do
    ddp = Factory(:daily_deal_purchase)
    recipient = ddp.recipients.create({
      :address_line_1 => "123 Alberta St",
      :address_line_2 => "Room 4",
      :city => "Portland",
      :state => "OR",
      :zip => "97211"
    })
    assert_equal false, recipient.valid?
    assert recipient.errors.on(:name)
  end
end
