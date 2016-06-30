require File.dirname(__FILE__) + "/../test_helper"

class GiftCertificatesControllerTest < ActionController::TestCase
  include ActionView::Helpers::NumberHelper

  assert_no_angle_brackets :none

  setup :assign_valid_attributes
                           
  def assign_valid_attributes
    @valid_attributes = {
      :message => "Message",
      :terms => "Terms",
      :price => 12.99,
      :value => 25.00,
      :number_allocated => 10
    }
  end

  def test_public_index_with_no_gift_certificates
    publisher = publishers(:my_space)
    assert publisher.gift_certificates.empty?
    assert_not_nil publisher.label

    get :public_index, :label => publisher.label

    assert_equal publisher, assigns(:publisher)
    assert_equal [], assigns(:gift_certificates)
    assert_layout "gift_certificates/public_index"

    assert_select "table.gift_certificates" do
      assert_select "tr", 1 do
        assert_select "td", /there are no deal certificates/i
      end
    end
  end
  
  def test_public_index_with_publisher_with_featured_gift_certificate
    gift_certificate = Factory :gift_certificate, :show_on => 1.hour.ago
    gift_certificate.publisher.update_attribute(:enable_featured_gift_certificate, true)

    get :public_index, :label => gift_certificate.publisher.label
    assert_response :success
    assert_select "tr.featured_gift_certificate"
  end

  def test_public_index_with_publisher_with_featured_gift_certificate_and_no_gift_certificates
    publisher = publishers(:my_space)
    publisher.update_attribute(:enable_featured_gift_certificate, true)
    assert publisher.gift_certificates.empty?
    assert_not_nil publisher.label

    get :public_index, :label => publisher.label

    assert_equal publisher, assigns(:publisher)
    assert_equal [], assigns(:gift_certificates)
    assert_layout "gift_certificates/public_index"

    assert_select "table.gift_certificates" do
      assert_select "tr", 1 do
        assert_select "td", /there are no deal certificates/i
      end
    end
  end

  def test_public_index_with_one_active_gift_certificate_but_no_referer_header
    publisher = publishers(:my_space)
    publisher.update_attribute(:gift_certificate_disclaimer, "this is my disclaimer")
    image = ActionController::TestUploadedFile.new("#{Rails.root}/test/fixtures/files/burger_king.png", "image/png")
    publisher.update_attributes! :paypal_checkout_header_image => image
    assert_not_nil publisher.label
    assert publisher.enable_paypal_buy_now?

    advertiser = publisher.advertisers.create!(:name => "My Advertiser")
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)
    assert publisher.gift_certificates(true).active.present?

    get :public_index, :label => publisher.label

    assert_equal publisher, assigns(:publisher)
    assert_equal [gift_certificate], assigns(:gift_certificates)
    assert_equal 1, gift_certificate.impressions
    assert_nil assigns(:return_url)
    assert_nil assigns(:upcoming_gift_certificates)
    assert_layout "gift_certificates/public_index"

    assert_select "table.gift_certificates" do
      assert_select "tr.gift_certificate", publisher.gift_certificates.active.size do
        assert_select "td.logo" 
        assert_select "td.message" do
          assert_select "h3", :text => "#{gift_certificate.advertiser_name} $25.00 Deal Certificate"
          assert_select "p"  
        end
        assert_select "td.purchase" do
          assert_select "form[action='#{Paypal::Notification.ipn_url}'][method=post]", 1 do
            assert_select "input[type=hidden][name=return_url]", false
            assert_select "input[type=hidden][name=cpp_header_image][value='https://s3.amazonaws.com/paypal-checkout-header-images.publishers.analoganalytics.com/test/#{publisher.id}/normal.png']", 1
            assert_select "input[type=image][src=http://www.paypal.com/en_US/i/btn/btn_buynowCC_LG.gif]"            
          end
        end
      end
      assert_select "tr.gift_certificate_terms", publisher.gift_certificates.active.size do
        assert_select "td", gift_certificate.plain_text_terms
      end
    end    
    assert_select "div.disclaimer", publisher.gift_certificate_disclaimer(:plain)
    assert_select "input[type=hidden][name='currency_code'][value='USD']"
  end

  def test_public_index_with_publisher_with_featured_gift_certificate_with_eur_currency
    publisher = publishers(:my_space)
    publisher.update_attribute(:gift_certificate_disclaimer, "this is my disclaimer")
    publisher.update_attribute(:currency_code, "EUR")

    assert_not_nil publisher.label
    assert publisher.enable_paypal_buy_now?

    advertiser = publisher.advertisers.create!(:name => "My Advertiser")
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)
    assert publisher.gift_certificates(true).active.present?

    get :public_index, :label => publisher.label
    assert_select "input[type=hidden][name='currency_code'][value='EUR']"
  end

  def test_public_index_with_active_gift_certificate_with_referer_header
    publisher = publishers(:my_space)
    assert_not_nil publisher.label
    assert publisher.enable_paypal_buy_now?

    advertiser = publisher.advertisers.create!( :name => "My Advertiser" )
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)
    assert publisher.gift_certificates(true).active.present?

    advertiser_2 = publisher.advertisers.create!( :name => "My Advertiser 2" )
    advertiser_2.gift_certificates.create!(@valid_attributes.merge(:expires_on => Date.today - 7))
    assert_equal 2, publisher.gift_certificates(true).count, "deal certificates"
    assert_equal 1, publisher.gift_certificates(true).active.count, "active deal certificates"

    referer = "http://www.mysite.com"

    @request.env['HTTP_REFERER'] = referer
    get :public_index, :label => publisher.label

    assert_equal publisher, assigns(:publisher)
    assert_not_nil assigns(:paypal_configuration)
    assert_equal [gift_certificate], assigns(:gift_certificates)
    assert_equal 1, gift_certificate.impressions
    assert_equal referer, assigns(:return_url)
    assert_layout "gift_certificates/public_index"

    assert_select "table.gift_certificates" do
      assert_select "tr.gift_certificate", publisher.gift_certificates.active.size do
        assert_select "td.logo" 
        assert_select "td.message" do
          assert_select "h3", :text => "#{gift_certificate.advertiser_name} $25.00 Deal Certificate"
          assert_select "p"  
        end
        assert_select "td.purchase" do
          assert_select "form[action='#{PaypalConfiguration.sandbox.ipn_url}']" do
            assert_select "input[type='hidden'][name='return_url']", true
            assert_select "input[type=hidden][name=cpp_header_image][value='https://test.host/images/missing/publishers/paypal_checkout_header_images/normal.png']", 1
            assert_select "input[type='image'][src='http://www.paypal.com/en_US/i/btn/btn_buynowCC_LG.gif']"            
          end
        end
      end
      assert_select "tr.gift_certificate_terms", publisher.gift_certificates.active.size do
        assert_select "td", gift_certificate.plain_text_terms
      end
    end    
  end  

  def test_public_index_without_publisher_enable_paypal_buy_now
    advertiser = advertisers(:burger_king)
    publisher = advertiser.publisher
    publisher.update_attributes! :enable_paypal_buy_now => false
    assert_not_nil publisher.label

    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)
    assert publisher.gift_certificates(true).active.present?

    get :public_index, :label => publisher.label

    assert_equal publisher, assigns(:publisher)
    assert_equal [gift_certificate], assigns(:gift_certificates)
    assert_equal 1, gift_certificate.impressions
    assert_layout "gift_certificates/public_index"

    assert_select "table.gift_certificates" do
      assert_select "tr.gift_certificate", publisher.gift_certificates.active.size do
        assert_select "td.logo" 
        assert_select "td.message" do
          assert_select "h3", :text => "#{gift_certificate.advertiser_name} $25.00 Deal Certificate"
          assert_select "p"  
        end
        assert_select "td.purchase" do
          assert_select "form[action='#{Paypal::Notification.ipn_url}']", 0
          assert_select "form[action=#][method=get]", 1 do
            assert_select "input[type='image'][src='http://www.paypal.com/en_US/i/btn/btn_buynowCC_LG.gif']"
          end
        end
      end
      assert_select "tr.gift_certificate_terms", publisher.gift_certificates.active.size do
        assert_select "td", gift_certificate.plain_text_terms
      end
    end    
  end

  def test_public_index_with_gift_certificate_id
    advertiser = advertisers(:burger_king)
    publisher = advertiser.publisher 
    gift_certificate_1 = advertiser.gift_certificates.create!(@valid_attributes)
    gift_certificate_2 = advertiser.gift_certificates.create!(@valid_attributes)
    get :public_index, :label => publisher.label, :gift_certificate_id => gift_certificate_2.to_param
    assert_equal 2, publisher.gift_certificates.size, "publisher should have 2 deal certificates"
    assert_equal [gift_certificate_2], assigns(:gift_certificates)
    assert_equal 0, gift_certificate_1.impressions
    assert_equal 1, gift_certificate_2.impressions
  end 

  def test_public_index_with_anchoragepress_publisher
    publisher = Factory(:publisher, :label => "anchoragepress")
    get :public_index, :label => publisher.label
    assert_layout   "gift_certificates/#{publisher.label}/public_index"
    assert_template "gift_certificates/#{publisher.label}/public_index"
  end

  def test_public_index_with_usd_currency_publisher
    usd_publisher = Factory :publisher, :currency_code => "USD"
    usd_advertiser = Factory :advertiser, :publisher_id => usd_publisher.id
    usd_gift_certificate = Factory :gift_certificate, :advertiser_id => usd_advertiser.id, :price => 18,
                           :value => 55, :show_on => 1.hour.ago
    
    get :public_index, :label => usd_publisher.label
    assert_response :success
    assert_select "table.gift_certificates td.purchase p.price", :text => "Only $18.00", :count => 1
    assert_select "table.gift_certificates td.purchase p.handling_fee", :text => "There&nbsp;is&nbsp;a&nbsp;$1.00&nbsp;handling&nbsp;fee."
  end
  
  def test_public_index_with_gbp_currency_publisher
    gbp_publisher = Factory :publisher, :currency_code => "GBP"
    gbp_advertiser = Factory :advertiser, :publisher_id => gbp_publisher.id
    gbp_gift_certificate = Factory :gift_certificate, :advertiser_id => gbp_advertiser.id, :price => 14,
                           :value => 32, :show_on => 1.hour.ago
    
    get :public_index, :label => gbp_publisher.label
    assert_response :success
    assert_select "table.gift_certificates td.purchase p.price", :text => "Only £14.00", :count => 1
    assert_select "table.gift_certificates td.purchase p.handling_fee", :text => "There&nbsp;is&nbsp;a&nbsp;£1.00&nbsp;handling&nbsp;fee."
  end
  
  def test_public_index_with_can_currency_publisher
    cad_publisher = Factory :publisher, :currency_code => "CAD"
    cad_advertiser = Factory :advertiser, :publisher_id => cad_publisher.id
    can_gift_certificate = Factory :gift_certificate, :advertiser_id => cad_advertiser.id, :price => 14,
                           :value => 32, :show_on => 1.hour.ago
    
    get :public_index, :label => cad_publisher.label
    assert_response :success
    assert_select "table.gift_certificates td.purchase p.price", :text => "Only C$14.00", :count => 1
    assert_select "table.gift_certificates td.purchase p.handling_fee", :text => "There&nbsp;is&nbsp;a&nbsp;C$1.00&nbsp;handling&nbsp;fee."
  end
  
  def test_show
    publisher = publishers(:my_space)
    advertiser = publisher.advertisers.create!( :name => "My Advertiser" )
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    assert publisher.enable_paypal_buy_now?, "publisher should be enabled for paypal"

    get :show, :id => gift_certificate.to_param

    assert_response :success
    assert assigns(:gift_certificate)
    assert assigns(:paypal_configuration), "should assign paypal configuration"
    assert_equal 1, gift_certificate.impressions
  end


  def test_preview_without_authenticated_account
    publisher = publishers(:my_space)
    advertiser = publisher.advertisers.create!( :name => "My Advertiser" )
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    get :preview, :id => gift_certificate.to_param

    assert_redirected_to new_session_path
  end    

  def test_preview_with_authenticated_account
    advertiser = advertisers(:di_milles)
    publisher  = advertiser.publisher
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    with_user_required(:aaron) do
      get :preview, :id => gift_certificate.to_param
    end

    assert_response :success
    assert_template :public_index
    assert_layout   'gift_certificates/public_index'
    assert assigns(:gift_certificate)
    assert_equal 0, gift_certificate.impressions      

  end

  def test_preview_pdf_without_authenticated_account
    publisher = publishers(:my_space)
    advertiser = publisher.advertisers.create!( :name => "My Advertiser" )
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    get :preview_pdf, :id => gift_certificate.to_param

    assert_redirected_to new_session_path
  end

  def test_preview_pdf_with_authenticated_account
    advertiser = advertisers(:di_milles)
    publisher  = advertiser.publisher
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    with_user_required(:aaron) do
      get :preview_pdf, :id => gift_certificate.to_param
    end

    assert_response :success

  end

  def test_new
    advertiser = advertisers(:changos)
    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit, role
      assert_not_nil assigns( :advertiser )
      assert_not_nil assigns( :gift_certificate )       

      assert_select "textarea[name='gift_certificate[message]']"
      assert_select "input[type='text'][name='gift_certificate[price]']"
      assert_select "input[type='text'][name='gift_certificate[value]']" 
      assert_select "input[type='text'][name='gift_certificate[handling_fee]']"
      assert_select "textarea[name='gift_certificate[terms]']"
      assert_select "input[type='text'][name='gift_certificate[show_on]']"
      assert_select "input[type='text'][name='gift_certificate[expires_on]']"      
      assert_select "input[type='text'][name='gift_certificate[number_allocated]']"
      assert_select "input[type='checkbox'][name='gift_certificate[physical_gift_certificate]']"
      assert_select "input[type='checkbox'][name='gift_certificate[collect_address]']"
      assert_select "input[type='file'][name='gift_certificate[logo]']", false
      assert_select "textarea[name='gift_certificate[description]']", false
      assert_select "input[type='text'][name='gift_certificate[bit_ly_url]']"      

    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :new, :advertiser_id => advertiser.to_param
    end
  end                                                                                

  def test_new_with_publisher_with_enabled_featured_gift_certificate
    advertiser = advertisers(:changos)

    advertiser.publisher.update_attribute(:enable_featured_gift_certificate, true)

    check_response = lambda { |role|
      assert_response :success, role
      assert_template :edit, role
      assert_not_nil assigns( :advertiser )
      assert_not_nil assigns( :gift_certificate ) 

      assert_not_nil assigns(:gift_certificate).advertiser

      assert_select "textarea[name='gift_certificate[message]']"
      assert_select "input[type='text'][name='gift_certificate[price]']"
      assert_select "input[type='text'][name='gift_certificate[value]']" 
      assert_select "input[type='text'][name='gift_certificate[handling_fee]']"
      assert_select "textarea[name='gift_certificate[terms]']"
      assert_select "input[type='text'][name='gift_certificate[show_on]']"
      assert_select "input[type='text'][name='gift_certificate[expires_on]']"
      assert_select "input[type='text'][name='gift_certificate[number_allocated]']"
      assert_select "input[type='checkbox'][name='gift_certificate[physical_gift_certificate]']"
      assert_select "input[type='checkbox'][name='gift_certificate[collect_address]']"
      assert_select "input[type='file'][name='gift_certificate[logo]']"
      assert_select "textarea[name='gift_certificate[description]']" 
      assert_select "input[type='text'][name='gift_certificate[bit_ly_url]']"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :new, :advertiser_id => advertiser.to_param
    end
  end  

  def test_create_with_valid_attributes
    advertiser = advertisers(:changos)
    advertiser.gift_certificates.destroy_all
    check_response = lambda { |role| 
      assert_redirected_to edit_advertiser_path(advertiser), role
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      post :create, :advertiser_id => advertiser.to_param, :gift_certificate => @valid_attributes
    end
  end

  def test_create_with_invalid_attributes
    advertiser = advertisers(:changos)
    advertiser.gift_certificates.destroy_all
    check_response = lambda { |role| 
      assert_template :edit, role
      assert !assigns(:gift_certificate).errors.empty?
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      post :create, :advertiser_id => advertiser.to_param, :gift_certificate => {}
    end
  end

  def test_edit
    advertiser = advertisers(:changos)
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    check_response = lambda { |role| 
      assert_template :edit, role
      assert_select "textarea[name='gift_certificate[message]']"
      assert_select "input[type='text'][name='gift_certificate[price]']"
      assert_select "input[type='text'][name='gift_certificate[value]']"
      assert_select "input[type='text'][name='gift_certificate[handling_fee]']"
      assert_select "textarea[name='gift_certificate[terms]']"               
      assert_select "input[type='text'][name='gift_certificate[show_on]']"
      assert_select "input[type='text'][name='gift_certificate[expires_on]']"
      assert_select "input[type='text'][name='gift_certificate[number_allocated]']"
      assert_select "input[type='checkbox'][name='gift_certificate[physical_gift_certificate]']"
      assert_select "input[type='checkbox'][name='gift_certificate[collect_address]']"
      assert_select "input[type='file'][name='gift_certificate[logo]']", false
      assert_select "textarea[name='gift_certificate[description]']", false
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :edit, :advertiser_id => advertiser.to_param, :id => gift_certificate.to_param
    end
  end

  def test_edit_with_publisher_with_enabled_featured_gift_certificate
    advertiser = advertisers(:changos)
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    advertiser.publisher.update_attribute(:enable_featured_gift_certificate, true)

    check_response = lambda { |role| 
      assert_template :edit, role
      assert_select "textarea[name='gift_certificate[message]']"
      assert_select "input[type='text'][name='gift_certificate[price]']"
      assert_select "input[type='text'][name='gift_certificate[value]']"  
      assert_select "input[type='text'][name='gift_certificate[handling_fee]']"      
      assert_select "textarea[name='gift_certificate[terms]']"               
      assert_select "input[type='text'][name='gift_certificate[show_on]']"
      assert_select "input[type='text'][name='gift_certificate[expires_on]']"
      assert_select "input[type='text'][name='gift_certificate[number_allocated]']"
      assert_select "input[type='checkbox'][name='gift_certificate[physical_gift_certificate]']"
      assert_select "input[type='checkbox'][name='gift_certificate[collect_address]']"
      assert_select "input[type='file'][name='gift_certificate[logo]']"
      assert_select "textarea[name='gift_certificate[description]']"
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      get :edit, :advertiser_id => advertiser.to_param, :id => gift_certificate.to_param
    end    
  end

  def test_update_with_valid_attributes
    advertiser = advertisers(:changos)
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    check_response = lambda { |role| 
      assert_redirected_to edit_advertiser_path(advertiser), role
      assert_equal "New message", gift_certificate.reload.message
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      post :update, :advertiser_id => advertiser.to_param, :id => gift_certificate.to_param, :gift_certificate => {:message => "New message", :price => 10.99}
    end    
  end

  def test_update_with_invalid_attributes
    advertiser = advertisers(:changos)
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    check_response = lambda { |role| 
      assert_template :edit, role
      assert !assigns(:gift_certificate).errors.empty?
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      post :update, :advertiser_id => advertiser.to_param, :id => gift_certificate.to_param, :gift_certificate => {:message => "", :price => 10.99}
    end    
  end 

  def test_destroy
    advertiser = advertisers(:changos)
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    check_response = lambda { |role| 
      assert_redirected_to edit_advertiser_path(advertiser), role
      assert gift_certificate.reload.deleted?
    }
    with_login_managing_advertiser_required(advertiser, check_response) do
      delete :destroy, :advertiser_id => advertiser.to_param, :id => gift_certificate.to_param
    end    
  end

  def test_twitter
    advertiser = advertisers(:changos)
    gift_certificate = advertiser.gift_certificates.create!(@valid_attributes)

    get :twitter, :id => gift_certificate.to_param
    assert_equal 1, gift_certificate.clicks
    assert_equal "twitter", gift_certificate.click_counts.first.mode
    assert_redirected_to "http://twitter.com/?status=#{CGI.escape(gift_certificate.twitter_status).gsub('+', '%20')}"
  end

  def test_facebook
    gift_certificate = Factory(:gift_certificate)
    advertiser = gift_certificate.advertiser
    gift_certificate.facebook_title_suffix = "Deal Certificate"
    image = "&p%5Bimages%5D%5B0%5D=#{CGI.escape(gift_certificate.logo.url)}"
    
    # gc with description and no image
    get :facebook, :id => gift_certificate.to_param
    assert_equal 1, gift_certificate.clicks
    assert_equal "facebook", gift_certificate.click_counts.first.mode
    gift_certificate_url = public_gift_certificates_url(gift_certificate.publisher.label, :gift_certificate_id => gift_certificate.to_param, :v => gift_certificate.updated_at.to_i)

    assert_redirected_to "http://www.facebook.com/share.php?s=100&p%5Burl%5D=#{CGI.escape(gift_certificate_url)}&p%5Btitle%5D=#{CGI.escape(gift_certificate.facebook_title)}&p%5Bsummary%5D=#{CGI.escape(gift_certificate.description)}#{image}"

    gift_certificate.description = nil
    gift_certificate.save
    
    # gc with no description and no image
    get :facebook, :id => gift_certificate.to_param
    assert_equal 2, gift_certificate.clicks
    gift_certificate_url = public_gift_certificates_url(gift_certificate.publisher.label, :gift_certificate_id => gift_certificate.to_param, :v => gift_certificate.updated_at.to_i)
    assert_redirected_to "http://www.facebook.com/share.php?s=100&p%5Burl%5D=#{CGI.escape(gift_certificate_url)}&p%5Btitle%5D=#{CGI.escape(gift_certificate.facebook_title)}#{image}"
  end
end
