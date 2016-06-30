require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Export::WhatCounts::WhatCountsTest
module Export
  module WhatCounts
    class WhatCountsTest < ActiveSupport::TestCase

      context "what counts file" do
        setup do
          @output = ""
          @file = SubscribeFile.new(@output, "my_realm", "my_password", 2112, "support@foo.bar")
        end
        context "construction" do
          should "have the fields assigned" do
            assert_equal @output, @file.output
            assert_equal 2112, @file.list_id
          end
        end
        context "the xml" do
          should "be able to build an empty wrapper" do
            @file.wrap_records
            expected = <<-EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<transaction>
  <realm>my_realm</realm>
  <password>my_password</password>
  <confirmation_email>support@foo.bar</confirmation_email>
  <command>
    <type>subscribe</type>
    <list_id>2112</list_id>
  </command>
</transaction>
            EXPECTED
            assert_equal expected, @output
          end

          should "be able to call wrap records with a block" do
            @file.wrap_records do |xml|
              xml.testing("expected")
            end
            expected = <<-EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<transaction>
  <realm>my_realm</realm>
  <password>my_password</password>
  <confirmation_email>support@foo.bar</confirmation_email>
  <command>
    <type>subscribe</type>
    <list_id>2112</list_id>
    <testing>expected</testing>
  </command>
</transaction>
            EXPECTED
            assert_equal expected, @output
          end

          should "be able to export subscriber emails" do
            @file.export_subscribers([{:email => "woodstock@peanuts.com"},
                                      {:email => "lucy@peanuts.com"},
                                      {:email => "snoopy@peanuts.com"}])
            expected = <<-EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<transaction>
  <realm>my_realm</realm>
  <password>my_password</password>
  <confirmation_email>support@foo.bar</confirmation_email>
  <command>
    <type>subscribe</type>
    <list_id>2112</list_id>
    <record>
      <email>woodstock@peanuts.com</email>
    </record>
    <record>
      <email>lucy@peanuts.com</email>
    </record>
    <record>
      <email>snoopy@peanuts.com</email>
    </record>
  </command>
</transaction>
            EXPECTED
            assert_equal expected, @output
          end

          should "include other fields if they're there" do
            @file.export_subscribers([{:email => "woodstock@peanuts.com", :last_name => "Woodstock"},
                                      {:email => "lucy@peanuts.com", :first_name => "Lucy"},
                                      {:email => "charlie@peanuts.com", :first_name => "Charlie", :last_name => "Brown", :zip_code => "97214"}])
            expected = <<-EXPECTED
<?xml version="1.0" encoding="UTF-8"?>
<transaction>
  <realm>my_realm</realm>
  <password>my_password</password>
  <confirmation_email>support@foo.bar</confirmation_email>
  <command>
    <type>subscribe</type>
    <list_id>2112</list_id>
    <record>
      <email>woodstock@peanuts.com</email>
      <last>Woodstock</last>
    </record>
    <record>
      <email>lucy@peanuts.com</email>
      <first>Lucy</first>
    </record>
    <record>
      <email>charlie@peanuts.com</email>
      <first>Charlie</first>
      <last>Brown</last>
      <zip>97214</zip>
    </record>
  </command>
</transaction>
            EXPECTED
            assert_equal expected, @output
          end

        end
      end

    end
  end
end
