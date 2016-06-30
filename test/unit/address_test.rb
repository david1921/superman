require File.dirname(__FILE__) + "/../test_helper"

class AddressTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  should "act as a location" do
    assert Address.ancestors.include?(ActsAsLocation)

    address = Address.new(:city => 'New York', :address_line_1 => nil, :country => Country::US)
    assert !address.valid?
    assert address.errors.on(:address_line_1).grep(/blank/)
  end
end
