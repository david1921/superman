# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::CallbacksTest < ActiveSupport::TestCase
  context "#update_bar_codes" do
    setup do
      @deal = Factory(:daily_deal)
    end

    should "add an error for an invalid csv format" do
      @deal.bar_codes_csv = "a,b,c\r\r\n"
      @deal.save
      assert_equal "Bar code csv file has invalid formatting", @deal.errors.on_base
    end

    context "distributed deal" do
      setup do
        @deal.available_for_syndication = true
        @deal.save!
        @syndicated_deal = syndicate(@deal, Factory(:publisher))
      end

      should "update bar codes without a validation error" do
        csv = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/bar_codes.csv", 'text/csv')
        @deal.bar_codes_csv = csv
        assert @deal.valid?, "Deal is invalid: #{@deal.errors.full_messages}"
        assert @deal.save!
      end
    end
  end
end
