require File.dirname(__FILE__) + "/../../test_helper"

class DailyDeal::PhotoTest < ActiveSupport::TestCase
  test "assignment of photo attachment with publisher dependent geometry" do
    publisher = Factory(:publisher, :label => "nydailynews")
    daily_deal = Factory.build(:daily_deal, :publisher => publisher, :advertiser => Factory(:advertiser, :publisher => publisher))
    daily_deal.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    daily_deal.save!
    assert_equal "300x276#", daily_deal.photo.styles[:email][:geometry]
  end
  
  test "assignment of photo attachment with default geometry" do
    daily_deal = Factory.build(:daily_deal)
    daily_deal.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    daily_deal.save!
    assert_equal "208x252>", daily_deal.photo.styles[:email][:geometry]
  end
  
  test "photo path" do
    path = DailyDeal.attachment_definitions[:photo][:path]
    assert_equal ":rails_env_fallback/:id/:style.:extension", path
  end

  test "photo uses production env photo path when SYNCH_PHOTOS is set" do
    ENV['SYNCH_PHOTOS'] = 'true'
    daily_deal = Factory.build(:daily_deal)
    daily_deal.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    daily_deal.save!
    assert_equal "production/#{daily_deal.id}/syndication.png", daily_deal.photo.path(:syndication)
  end

  test "photo uses test env photo path when SYNCH_PHOTOS is not set" do
    ENV['SYNCH_PHOTOS'] = nil
    daily_deal = Factory.build(:daily_deal)
    daily_deal.photo = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/large.png", 'image/png')
    daily_deal.save!
    assert_equal "test/#{daily_deal.id}/syndication.png", daily_deal.photo.path(:syndication)
  end
end
