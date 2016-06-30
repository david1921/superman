require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDeals::CopySourceDealPhotosTest
module DailyDeals
  class CopySourceDealPhotosTest < ActiveSupport::TestCase
    context "perform" do
      setup do
        photo_path = "#{Rails.root}/test/fixtures/files/large.png"
        photo = ActionController::TestUploadedFile.new(photo_path, 'image/png')
        secondary_photo = ActionController::TestUploadedFile.new(photo_path, 'image/png')

        @publisher1 = Factory(:publisher, :in_syndication_network => true)
        @publisher2 = Factory(:publisher, :in_syndication_network => true)
        @source_deal = Factory(:daily_deal,
                               :publisher => @publisher1,
                               :available_for_syndication => true,
                               :photo => photo,
                               :secondary_photo => secondary_photo)
        @syndicated_deal = Factory(:daily_deal,
                                   :source => @source_deal,
                                   :publisher => @publisher2,
                                   :photo => nil,
                                   :secondary_photo => nil)

        AWS::S3::S3Object.stubs(:value)
        AWS::S3::S3Object.stubs(:get)

        CopySourceDealPhotos.perform(@syndicated_deal.id)
      end

      should "copy deal photo" do
        @syndicated_deal.reload
        assert_equal @source_deal.photo_content_type, @syndicated_deal.photo_content_type
      end

      should "copy deal secondary photo" do
        @syndicated_deal.reload
        assert_equal @source_deal.secondary_photo_content_type, @syndicated_deal.secondary_photo_content_type
      end
    end

  end
end
