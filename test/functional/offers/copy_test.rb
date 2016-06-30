require File.dirname(__FILE__) + "/../../test_helper"

class OffersController::CopyTest < ActionController::TestCase
  tests OffersController
  should "copy the attributes from the source offer" do 
    @advertiser = Factory(:advertiser, :publisher => Factory(:publisher))
    @source_offer = Factory(:offer, :advertiser => @advertiser)
    @source_offer.stubs(:message).returns("Area Rugs")
    @source_offer.stubs(:category_names).returns("Flooring")

  	login_as_admin
    get :copy, :id => @source_offer.id, :advertiser_id => @advertiser.id 
    assert assigns(:offer)
    assert @source_offer.message, assigns(:offer).message
  	assert @source_offer.category_names, assigns(:offer).category_names
    assert_nil assigns(:offer).bit_ly_url 
  end

  protected
  def login_as_admin
    @controller.stubs(:current_user).returns(Factory(:admin))
  end
end