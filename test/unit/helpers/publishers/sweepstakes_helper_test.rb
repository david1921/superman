require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Publishers::SweepstakesHelperTest

module Publishers
  
  class SweepstakesHelperTest < ActionView::TestCase
    
    context "sweepstake_promo_email_checkbox_text" do
      
      setup do
        @publisher = Factory :publisher, :name => "Test Publisher"
        @sweepstake = Factory :sweepstake, :publisher => @publisher
      end
      
      should "return text with the publisher name, when Sweepstake#promotional_opt_in_text is blank" do
        assert @sweepstake.promotional_opt_in_text.blank?
        assert_equal "Check here to receive emails from Test Publisher about its products and future promotions.", sweepstake_promo_email_checkbox_text(@sweepstake)
      end
      
      should "return text with Sweepstake#promotional_opt_in_text, when present" do
        @sweepstake.promotional_opt_in_text = "Some cool promotion"
        assert_equal "Some cool promotion", sweepstake_promo_email_checkbox_text(@sweepstake)
      end
      
    end
    
  end
  
end