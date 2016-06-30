require File.dirname(__FILE__) + "/../test_helper"

class PhoneNumberTest < ActiveSupport::TestCase
  setup :create_countries
  
  def create_countries
    Factory(:country, :code => "GR", :calling_code => "30", :phone_number_length => 10)
    Factory(:country, :code => "FB", :calling_code => "999", :phone_number_length => nil)
    Factory(:country, :code => "ZZ", :calling_code => nil, :phone_number_length => nil)
  end

  def test_validity_and_conversions
    test_case({ :text => nil, :valid => false })
    test_case({ :text => "", :valid => false })
    test_case({ :text => "626-674-5901",        :valid => true, :to_attribute_s => "16266745901",         :to_formatted_s => "(626) 674-5901" })
    test_case({ :text => "800-CALL-ATT",        :valid => true, :to_attribute_s => "1800-CALL-ATT",       :to_formatted_s => "800-CALL-ATT" })
    test_case({ :text => "800-call-att",        :valid => true, :to_attribute_s => "1800-CALL-ATT",       :to_formatted_s => "800-CALL-ATT" })
    test_case({ :text => "626 674 5901",        :valid => true, :to_attribute_s => "16266745901",         :to_formatted_s => "(626) 674-5901" })
    test_case({ :text => "(626) 674-5901",      :valid => true, :to_attribute_s => "16266745901",         :to_formatted_s => "(626) 674-5901" })
    test_case({ :text => "626-674-590",         :valid => false })
    test_case({ :text => "626-674-59012",       :valid => false })
    test_case({ :text => "800-EAT-PIZZA",       :valid => true, :to_attribute_s => "1800-EAT-PIZZA",      :to_formatted_s => "800-EAT-PIZZA" })
    test_case({ :text => "1-360-456-6407",      :valid => true, :to_attribute_s => "13604566407",         :to_formatted_s => "(360) 456-6407" })
    test_case({ :text => "16266745901",         :valid => true, :to_attribute_s => "16266745901",         :to_formatted_s => "(626) 674-5901" })
    test_case({ :text => "1800-CALL-ATT",       :valid => true,  :to_attribute_s => "1800-CALL-ATT",      :to_formatted_s => "800-CALL-ATT" })
    test_case({ :text => "162667459012",        :valid => false })
    test_case({ :text => "1800-EAT-PIZZA",      :valid => true, :to_attribute_s => "1800-EAT-PIZZA",      :to_formatted_s => "800-EAT-PIZZA" })
    test_case({ :text => "1504-779-7749-EXT21", :valid => true, :to_attribute_s => "1504-779-7749-EXT21", :to_formatted_s => "504-779-7749-EXT21" })
    test_case({ :text => "858*123!4567",        :valid => true, :to_attribute_s => "18581234567",         :to_formatted_s => "(858) 123-4567" })
    test_case({ :text => "123-4567",            :valid => false })
    test_case({ :text => "1234567",             :valid => false })
    test_case({ :text => "123-4567",            :valid => true, :to_attribute_s => "1234567",  :to_formatted_s => "123-4567", :options => {:allow_seven_digit_phone_numbers => true} })
    test_case({ :text => "1234567",             :valid => true, :to_attribute_s => "1234567",  :to_formatted_s => "123-4567", :options => {:allow_seven_digit_phone_numbers => true} })
    test_case({ :text => "BROWNIE",             :valid => true, :to_attribute_s => "BROWNIE",  :to_formatted_s => "BROWNIE", :options => {:allow_seven_digit_phone_numbers => true} })
    test_case({ :text => "123-CAKE",            :valid => true, :to_attribute_s => "123-CAKE", :to_formatted_s => "123-CAKE", :options => {:allow_seven_digit_phone_numbers => true} })
    test_case({ :text => "12-CAKE",             :valid => false, :options => {:allow_seven_digit_phone_numbers => true} })
    test_case({ :text => "5124161500",          :valid => true, :to_attribute_s => "15124161500", :to_formatted_s => "(512) 416-1500", :options => {:allow_seven_digit_phone_numbers => true} })
    test_case({ :text => "15124161500",         :valid => true, :to_attribute_s => "15124161500", :to_formatted_s => "(512) 416-1500", :options => {:allow_seven_digit_phone_numbers => true} })

    test_case({ :text => "0125255555555",      :country_code => Country::UK.code, :valid => false })
    test_case({ :text => "0800 9 55 44 55",    :country_code => Country::UK.code, :valid => true, :to_attribute_s => "4408009554455", :to_formatted_s => "08009 554 455" })
    test_case({ :text => "01252 555 555",      :country_code => Country::UK.code, :valid => true, :to_attribute_s => "4401252555555", :to_formatted_s => "01252 555 555" })
    test_case({ :text => "01252555555",        :country_code => Country::UK.code, :valid => true, :to_attribute_s => "4401252555555", :to_formatted_s => "01252 555 555" })
    test_case({ :text => "440125255555555",    :country_code => Country::UK.code, :valid => false })
    test_case({ :text => "44 0800 9 55 44 55", :country_code => Country::UK.code, :valid => true, :to_attribute_s => "4408009554455", :to_formatted_s => "08009 554 455" })
    test_case({ :text => "44 01252 555 555",   :country_code => Country::UK.code, :valid => true, :to_attribute_s => "4401252555555", :to_formatted_s => "01252 555 555" })
    test_case({ :text => "4401252555555",      :country_code => Country::UK.code, :valid => true, :to_attribute_s => "4401252555555", :to_formatted_s => "01252 555 555" })
    test_case({ :text => "1234567",            :country_code => Country::UK.code, :valid => false, :options => {:allow_seven_digit_phone_numbers => true} })
    test_case({ :text => "302108026050", :country_code => "GR", :valid => true, :to_attribute_s => "302108026050", :to_formatted_s => "302108026050" })
    test_case({ :text => "348237942384792384729384", :country_code => "FB", :valid => true, :to_attribute_s => "348237942384792384729384", :to_formatted_s => "348237942384792384729384" })
    test_case({ :text => "12345", :country_code => "ZZ", :valid => true, :to_attribute_s => "12345", :to_formatted_s => "12345" })
  end
  
  private
  
  def test_case(options)
    phone_number = PhoneNumber.new(options[:text], options[:country_code], options[:options])
    if options[:valid]
      assert phone_number.valid?, "#{options[:text]} is not a valid phone number"
      assert_equal options[:to_attribute_s], phone_number.to_attribute_s, "attribute string"
      assert_equal options[:to_formatted_s], phone_number.to_formatted_s, "formatted string"
    else
      assert !phone_number.valid?, "#{options[:text]} should not be a valid phone number"
    end
  end
end
