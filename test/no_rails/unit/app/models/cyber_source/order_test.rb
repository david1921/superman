require File.dirname(__FILE__) + "/../../models_helper"

class CyberSource::OrderTest < Test::Unit::TestCase

  context "with VISA card" do

    setup do
      @order = CyberSource::Order.new(
          "card_accountNumber" => "411111######1111"
      )
    end

    context "#credit_card_bin" do
      should "return first 6 digits" do
        assert_equal "411111", @order.credit_card_bin
      end
    end

    context "#card_last_4" do
      should "return last 4 digits" do
        assert_equal "1111", @order.card_last_4
      end
    end

  end

  context "with AMEX card" do

    setup do
      @order = CyberSource::Order.new(
        "card_accountNumber" => "37###########06"
      )
    end

    context "#credit_card_bin" do
      should "return first 6 characters" do
        assert_equal "37####", @order.credit_card_bin
      end
    end

    context "#card_last_4" do
      should "return last 4 characters" do
        assert_equal "##06", @order.card_last_4
      end
    end

  end


end
