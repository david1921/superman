# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::CreateTest < ActiveSupport::TestCase
  setup :setup_valid_attributes

  test "create" do
    daily_deal = advertisers(:burger_king).daily_deals.create!(@valid_attributes)
    assert_equal advertisers(:burger_king), daily_deal.advertiser, "should assign advertiser"
    assert_equal advertisers(:burger_king).publisher, daily_deal.publisher, "should assign publisher"

    assert       !daily_deal.deleted?, "should not be deleted"
    assert_equal 2, Advertiser.find(advertisers(:burger_king).id).daily_deals.size
    assert_equal 1, Advertiser.find(advertisers(:burger_king).id).daily_deals.active.size
    assert       daily_deal.bit_ly_url.present?
    assert_equal "http://#{daily_deal.publisher.host}/daily_deals/#{daily_deal.id}", daily_deal.url_for_bit_ly
    assert_equal "MySpace Deal of the Day: $81 value for $39", daily_deal.facebook_title
    assert_equal "Burger King: Have it your way; $81 value for $39; these are my terms.", daily_deal.facebook_description
    assert_equal "MySpace Deal of the Day: $81 value for $39 at Burger King #{daily_deal.bit_ly_url}", daily_deal.twitter_status
    assert daily_deal.facebook_title_text.blank?, "Facebook title text should be blank by default"
    assert daily_deal.twitter_status_text.blank?, "Twitter status text should be blank by default"
    assert_equal "BBD-#{daily_deal.id}", daily_deal.listing, "listing default"
    assert !daily_deal.hide_serial_number_if_bar_code_is_present, "should defaulthide_serial_number_if_bar_code_is_present to false"
  end

  test "create with listing" do
    daily_deal = advertisers(:burger_king).daily_deals.create!(@valid_attributes.merge(:listing => "MYLISTING"))
    assert_equal "MYLISTING", daily_deal.listing, "should use supplied listing value, and not default"
  end

  test "create with no expires on" do
    daily_deal = advertisers(:burger_king).daily_deals.create!(@valid_attributes.except(:expires_on))
    assert_equal advertisers(:burger_king), daily_deal.advertiser, "should assign advertiser"
    assert_equal advertisers(:burger_king).publisher, daily_deal.publisher, "should assign publisher"

    assert !daily_deal.expired?, "should not be expired"
  end

  test "create with expires on in the future" do
    daily_deal = advertisers(:burger_king).daily_deals.create!(@valid_attributes.merge(:expires_on => 2.days.from_now))
    assert_equal advertisers(:burger_king), daily_deal.advertiser, "should assign advertiser"
    assert_equal advertisers(:burger_king).publisher, daily_deal.publisher, "should assign publisher"

    assert !daily_deal.expired?, "should not be expired"
  end

  test "create with expires on in the past" do
    daily_deal = advertisers(:burger_king).daily_deals.create!(@valid_attributes.merge(
                                                                   :hide_at => 2.days.ago,
                                                                   :expires_on => 1.day.ago
                                                               ))
    assert_equal advertisers(:burger_king), daily_deal.advertiser, "should assign advertiser"
    assert_equal advertisers(:burger_king).publisher, daily_deal.publisher, "should assign publisher"

    assert daily_deal.expired?, "should be expired"
  end

  test "create with hide at in the future" do
    daily_deal = advertisers(:burger_king).daily_deals.create!(@valid_attributes.merge(:hide_at => 2.days.from_now))
    assert_equal advertisers(:burger_king), daily_deal.advertiser, "should assign advertiser"
    assert_equal advertisers(:burger_king).publisher, daily_deal.publisher, "should assign publisher"

    assert daily_deal.available?, "should be available"
    assert_equal 1, Advertiser.find(advertisers(:burger_king).id).daily_deals.active.size
  end

  test "create with hide at in the past" do
    daily_deal = advertisers(:burger_king).daily_deals.create!(@valid_attributes.merge(:hide_at => 1.day.ago))
    assert_equal advertisers(:burger_king), daily_deal.advertiser, "should assign advertiser"
    assert_equal advertisers(:burger_king).publisher, daily_deal.publisher, "should assign publisher"

    assert !daily_deal.available?, "should not be available"
    assert_equal 0, Advertiser.find(advertisers(:burger_king).id).daily_deals.active.size
  end


  test "create with publisher with default voucher steps" do
    publisher = Factory(:publisher, :label => "justdefaults")
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = advertiser.daily_deals.build(@valid_attributes.merge(:publisher => publisher))
    daily_deal.assign_defaults
    daily_deal.save!

    assert_equal "1. Print your voucher\n2. Go to #{advertiser.name}\n3. Present voucher and valid ID upon arrival", daily_deal.reload.voucher_steps
  end

  test "create with publisher with non-default voucher steps" do
    publisher = Factory(:publisher, :label => "nydailynews")
    advertiser = Factory(:advertiser, :publisher => publisher)
    daily_deal = advertiser.daily_deals.build(@valid_attributes.merge(:publisher => publisher))
    daily_deal.assign_defaults
    daily_deal.save!

    assert_equal "1. Print your voucher\n2. Present to advertiser or follow the Fine Print Instructions\n3. Enjoy", daily_deal.reload.voucher_steps
  end

  private

  def setup_valid_attributes
    @valid_attributes = {
      :value_proposition => "$81 value for $39",
      :price => 39.00,
      :value => 81.00,
      :quantity => 100,
      :terms => "these are my terms",
      :description => "this is my description",
      :start_at => 10.days.ago,
      :hide_at => Time.zone.now.tomorrow,
      :short_description => "A wonderful deal"
    }
  end

end
