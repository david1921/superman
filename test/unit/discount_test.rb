require File.dirname(__FILE__) + "/../test_helper"

class DiscountTest < ActiveSupport::TestCase
  test "code is normalized after validation" do
    discount = Discount.new(:publisher => Factory(:publisher), :code => " my code 1 ", :amount => 10)
    assert discount.valid?, "Should be valid"
    assert_equal "MYCODE1", discount.code
  end
  
  test "uuid present after save" do
    discount = Discount.new(:publisher => Factory(:publisher), :code => " my code 1 ", :amount => 10)
    assert discount.save
    assert_match /\A[[:xdigit:]]{8}-([[:xdigit:]]{4}-){3}[[:xdigit:]]{12}\z/, discount.uuid
  end
  
  test "not usable if marked deleted" do
    discount = Discount.new(:publisher => Factory(:publisher), :code => " my code 1 ", :amount => 10)
    assert discount.valid?, "Should be valid"
    assert discount.usable?, "Should be usable before setting deleted"
    discount.set_deleted!
    assert discount.deleted?, "Should be marked deleted"
    assert !discount.usable?, "Should not be usable after set deleted"
  end

  test "not usable if used_at and usable_only_once are both set" do
    discount = Factory(:discount, :used_at => Time.now, :usable_only_once => true)
    assert !discount.usable?, "Should not be usable if already used (used_at)"
    assert !Discount.usable.exists?(discount), "Should not be found by usable scope"
  end
  
  test "not usable if now is before first_usable_at" do
    discount = Discount.create!(:publisher => Factory(:publisher), :code => " my code 1 ", :amount => 10, :first_usable_at => "Aug 15, 2010 12:34:56")
    Time.zone.stubs(:now).returns Time.zone.parse("Aug 15, 2010 12:00:00")
    assert !discount.usable?, "Should not be usable before first_usable_at"
    assert !Discount.usable.exists?(discount), "Should not be found by usable scope"
  end

  test "not usable if now is after last_usable_at" do
    discount = Discount.create!(:publisher => Factory(:publisher), :code => " my code 1 ", :amount => 10, :last_usable_at => "Aug 15, 2010 12:34:56")
    Time.zone.stubs(:now).returns Time.zone.parse("Aug 15, 2010 13:00:00")
    assert !discount.usable?, "Should not be usable after last_usable_at"
    assert !Discount.usable.exists?(discount), "Should not be found by usable scope"
  end

  test "usable if now is between first_usable_at and last_usable_at" do
    discount = Discount.create!(
      :publisher => Factory(:publisher),
      :code => " my code 1 ",
      :amount => 10,
      :first_usable_at => "Aug 15, 2010 11:00:00",
      :last_usable_at => "Aug 15, 2010 12:00:00"
    )
    Time.zone.stubs(:now).returns Time.zone.parse("Aug 15, 2010 11:30:00")
    assert discount.usable?, "Should be usable between first_usable_at and last_usable_at"
    assert Discount.usable.exists?(discount), "Should be found by usable scope"
  end
  
  test "code must be unique for one publisher if not deleted" do
    publisher = Factory(:publisher)
    Discount.create! :publisher => publisher, :code => " my code 1 ", :amount => 10
    discount = Discount.new(:publisher => publisher, :code => "MYCODE1", :amount => 20)
    assert !discount.valid?
    assert_match /already in use/i, discount.errors.on(:code)
  end

  test "code can be repeated for one publisher if deleted" do
    publisher = Factory(:publisher)
    discount = Discount.create!(:publisher => publisher, :code => " my code 1 ", :amount => 10)
    discount.set_deleted!
    
    discount = Discount.new(:publisher => publisher, :code => "MYCODE1", :amount => 20)
    assert discount.valid?, "Should be valid with repeated code deleted"
  end

  test "code can be repeated across publishers" do
    Discount.create! :publisher => Factory(:publisher), :code => " my code 1 ", :amount => 10
    discount = Discount.new(:publisher => Factory(:publisher), :code => "MYCODE1", :amount => 20)
    assert discount.valid?, "Should be valid with unique code for own publisher"
  end

  test "usable_only_once?" do
    discount = Factory(:discount)
    assert !discount.usable_only_once?
    discount.update_attribute(:usable_only_once, true)
    assert discount.usable_only_once?
  end

  test "use!" do
    discount = Factory(:discount)
    assert !discount.used_at, "Should not be used"
    discount.use!
    assert discount.used_at, "Should be used"
  end

  context "validations" do
    context "amount" do
      should "be valid when zero" do
        discount = Factory.build(:discount, :amount => 0)
        assert discount.valid?
      end
    end
  end

  should belong_to(:daily_deal_purchase)

end
