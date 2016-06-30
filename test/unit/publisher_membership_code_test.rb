require File.dirname(__FILE__) + "/../test_helper"

class PublisherMembershipCodeTest < ActiveSupport::TestCase
  should belong_to(:publisher)
  should validate_presence_of(:code)
  should validate_presence_of(:publisher)

  should "validate unqiueness of code within publishing group" do
    publishing_group1 = Factory(:publishing_group)
    publishing_group2 = Factory(:publishing_group)

    publisher1 = Factory(:publisher, :publishing_group => publishing_group1)
    publisher2 = Factory(:publisher, :publishing_group => publishing_group2)

    code1 = Factory(:publisher_membership_code, :code => "ABC", :publisher => publisher1)
    code2 = Factory.build(:publisher_membership_code, :code => "ABC", :publisher => publisher1)
    code3 = Factory(:publisher_membership_code, :code => "ABC", :publisher => publisher2)

    assert code1.valid?
    assert !code2.valid?
    assert code3.valid?
  end
end
