require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::ThemesOffersTest
module Publishers
  class ThemesOffersTest < ActiveSupport::TestCase

    STUBBED_TEMPLATES = [
      ['layouts/gift_certificates/tampagoods/public_index.html.liquid', false],
      ['layouts/gift_certificates/creativeloafing/public_index.html.liquid', true],
      ['layouts/subscribers/newsday/public_index.html.liquid', true],
      ['layouts/gift_certificates/bedbugsmattressguard/public_index.html.erb', true],
      ['layouts/gift_certificates/bedbugsmattressguard/public_index.html.liquid', false],
      ['layouts/gift_certificates/doesntexist/public_index.html.liquid', false],
      ['layouts/gift_certificates/doesntexist/public_index.html.erb', false],
      ['gift_certificates/creativeloafing/public_index.liquid', true],
      ['gift_certificates/tampagoods/public_index.html.erb', false],
      ['gift_certificates/tampagoods/public_index.html.liquid', false],
      ['gift_certificates/tampagoods/public_index.liquid', false],
      ['gift_certificates/bedbugsmattressguard/public_index.html.erb', true],
      ['gift_certificates/doesntexist/public_index.html.liquid', false],
      ['gift_certificates/doesntexist/public_index.liquid', false],
      ['gift_certificates/doesntexist/public_index.html.erb', false],
      ['gift_certificates/enhanced/public_index.html.erb', false],
      ['subscribers/newsday/thank_you.html.erb', true]
    ]

    include Publishers::Themes::Offers

    context "template themeing with Publishers::Themes::Offers" do

      setup do
        @bedbugsmattressguard = Factory :publisher, :label => "bedbugsmattressguard"
        @doesnt_exist = Factory :publisher, :label => "doesntexist"
        @newsday = Factory :publisher, :label => "newsday"
        @creativeloafing = Factory :publishing_group, :label => "creativeloafing"
        @tampagoods = Factory :publisher, :label => "tampagoods", :publishing_group_id => @creativeloafing.id

        STUBBED_TEMPLATES.each do |template|
          path, exists = template
          File.stubs(:exists?).with("#{Rails.root}/app/views/#{path}").returns(exists)
        end
      end

      context "#layout_for_publisher" do

        should "return the liquid template name for a publisher group label, when only the " +
               "publisher group has a matching liquid template for a layout" do
          @controller_name = "gift_certificates"
          assert_equal "gift_certificates/creativeloafing/public_index.html.liquid",
                       layout_for_publisher(@tampagoods)
        end

        should "return the liquid template name for a publisher label, when a specific " +
               "publisher has a matching liquid template for a layout" do
          @controller_name = "subscribers"
          assert_equal "subscribers/newsday/public_index.html.liquid", layout_for_publisher(@newsday)
        end

        should "return the erb template name for a publisher label, when a specific " +
               "publisher has a matching erb template for a layout" do
          @controller_name = "gift_certificates"
          assert_equal "gift_certificates/bedbugsmattressguard/public_index.html.erb",
                       layout_for_publisher(@bedbugsmattressguard)
        end

        should "return a default layout name, when the publisher has no matching layout" do
          @controller_name = "gift_certificates"
          assert_equal "gift_certificates/public_index", layout_for_publisher(@doesnt_exist)
        end

      end 

      context "#template_for_publisher" do

        should "return the liquid template name for a publisher group label, when only the " +
               "publisher group has a matching liquid template" do
          @controller_name = "gift_certificates"
          assert_equal "gift_certificates/creativeloafing/public_index",
                       template_for_publisher(@tampagoods, "public_index")
        end

        should "return the liquid template name for a publisher label, when a specific " +
               "publisher has a matching liquid template" do
          @controller_name = "subscribers"
          assert_equal "subscribers/newsday/thank_you", template_for_publisher(@newsday, "thank_you")
        end

        should "return the erb template name for a publisher label, when a specific " +
               "publisher has a matching erb template" do
          @controller_name = "gift_certificates"
          assert_equal "gift_certificates/bedbugsmattressguard/public_index",
                       template_for_publisher(@bedbugsmattressguard, "public_index")
        end

        should "return a default template name, when the publisher has no matching template" do
          @controller_name = "gift_certificates"
          assert_equal "gift_certificates/public_index", template_for_publisher(@doesnt_exist, "public_index")
        end

      end

    end

    def controller_name
      @controller_name
    end 

  end
end

