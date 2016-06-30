require File.dirname(__FILE__) + "/../test_helper"

class CountryTest < ActiveSupport::TestCase

 def test_equal_by_code
   us1 = Factory.build(:country, :code => "US")
   us2 = Country::US
   assert_equal us1, us2
 end

 context "postal_code_regex" do

   setup do
     # should not be necessary
     # in hydra this sometimes seems necessary though
     fb = Country.find_by_code("FB")
     fb.destroy if fb.present?
   end

   should "return a useable regexp" do
     Factory(:country, :code => "FB", :postal_code_regex => "foo.*bar")
     assert "fooohyeahbar" =~ Country.postal_code_regex("FB")
   end

   should "return nil if regexp is nil" do
     Factory(:country, :code => "FB", :postal_code_regex => nil)
     assert_nil Country.postal_code_regex("FB")
   end

   should "return nil if regexp is empty" do
     Factory(:country, :code => "FB", :postal_code_regex => "")
     assert_nil Country.postal_code_regex("FB")
   end

   should "return nil if there is no matching country" do
     Factory(:country, :code => "FB", :postal_code_regex => nil)
     assert_nil Country.postal_code_regex("ZZ")
   end

 end

 context "Country.const_missing" do
   setup do
     fb = Country.find_by_code("XY")
     fb.destroy if fb.present?
   end
   should "Find countries that exist" do
     assert_equal Country.find_by_code("US"), Country::US
     Factory(:country, :code => "XY")
     assert_equal Country.find_by_code("XY"), Country::XY
   end
   should "raise if no country" do
     assert_raise Country::NoSuchCountry do
       Country::PQ
     end
   end
 end

 context "Country method_missing for is that this country predicates" do
   setup do
     fb = Country.find_by_code("XY")
     fb.destroy if fb.present?
   end
   should "Work for the existing countries" do
     assert Country::US.us?
     assert !Country::US.uk?
     Factory(:country, :code => "XY")
     assert Country::XY.xy?
     assert !Country::XY.us?
   end
 end

 context "uniqueness of code" do
   setup do
     fb = Country.find_by_code("FB")
     fb.destroy if fb.present?
   end
   should "invalid if country with code already exists" do
     Factory(:country, :code => "FB")
     c = Factory.build(:country, :code => "FB")
     assert !c.valid?
   end
 end

end
