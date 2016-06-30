require File.dirname(__FILE__) + "/../test_helper"

class DailyDealVariationsControllerTest < ActionController::TestCase

  context "new" do

    setup do
      @daily_deal = Factory(:daily_deal, :value_proposition_subhead => "this is the subhead", :voucher_headline => "this is voucher headline")
      @daily_deal.publisher.update_attribute(:self_serve, true)
    end

    context "without an account" do

      should "redirect to the new session path" do
        get :new, :daily_deal_id => @daily_deal.to_param
        assert_redirected_to new_session_path
      end
    end

    context "with a user account not associated with the daily deal" do

      should "redirect to the new session path" do
        login_as Factory(:user)
        get :new, :daily_deal_id => @daily_deal.to_param
        assert_redirected_to new_session_path
      end
      
    end

    context "with a user account associated with the daily deal" do

      setup do
        @user = Factory(:user, :company => @daily_deal.publisher)
      end

      should "be able to manage current publisher" do
        assert @user.can_manage?(@daily_deal.publisher)
      end

      should "display the edit template with default values" do
        login_as @user
        get :new, :daily_deal_id => @daily_deal.to_param
        assert assigns(:daily_deal), "should assign daily deal"
        assert assigns(:daily_deal_variation), "should assign daily deal variation"
        assert_template "edit"
        assert_layout "application"
        assert_select "form[action='#{daily_deal_daily_deal_variations_path(@daily_deal)}'][method='post']" do          
          assert_select "input[type=hidden][name='_method'][value='put']", false
          assert_select "input[type=text][name='daily_deal_variation[value_proposition_subhead]'][value='#{@daily_deal.value_proposition_subhead}']"
          assert_select "input[type=text][name='daily_deal_variation[value_proposition]'][value='#{@daily_deal.value_proposition}']"
          assert_select "input[type=text][name='daily_deal_variation[voucher_headline]'][value='#{@daily_deal.voucher_headline}']"
          assert_select "input[type=text][name='daily_deal_variation[value]'][value='#{@daily_deal.value}']"
          assert_select "input[type=text][name='daily_deal_variation[price]'][value='#{@daily_deal.price}']"
          assert_select "input[type=text][name='daily_deal_variation[value_proposition_subhead]'][value='#{@daily_deal.value_proposition_subhead}']"
          assert_select "input[type=text][name='daily_deal_variation[listing]']"

          assert_select "input[type=text][name='daily_deal_variation[affiliate_url]']"

          # quantity do not have default values, since they delegate to the daily deal if not set.
          assert_select "input[type=text][name='daily_deal_variation[quantity]']"
          assert_select "input[type=text][name='daily_deal_variation[min_quantity]'][value='#{@daily_deal.min_quantity}']"
          assert_select "input[type=text][name='daily_deal_variation[max_quantity]'][value='#{@daily_deal.max_quantity}']"
          
          assert_select "select[name='daily_deal_variation[certificates_to_generate_per_unit_quantity]']"

          # barcodes
          assert_select "input[type=file][name='daily_deal_variation[bar_codes_csv]']"
          assert_select "select[name='daily_deal_variation[bar_code_encoding_format]']"
          assert_select "input[type=checkbox][name='daily_deal_variation[allow_duplicate_bar_codes]']"
          assert_select "input[type=checkbox][name='daily_deal_variation[delete_existing_unassigned_bar_codes]']"

          assert_select "textarea[name='daily_deal_variation[terms]']", :text => /these are my terms/
          assert_select "input[type=submit][value='Save']"
        end
      end
    end

    context "with an admin account" do

      should "display the edit template with default values" do
        login_as Factory(:admin)
        get :new, :daily_deal_id => @daily_deal.to_param
        assert assigns(:daily_deal), "should assign daily deal"
        assert assigns(:daily_deal_variation), "should assign daily deal variation"
        assert_template "edit"
        assert_layout "application"

        assert_select "form[action='#{daily_deal_daily_deal_variations_path(@daily_deal)}'][method='post']" do
          assert_select "input[type=hidden][name='_method'][value='put']", false
          assert_select "input[type=text][name='daily_deal_variation[value_proposition_subhead]'][value='#{@daily_deal.value_proposition_subhead}']"
          assert_select "input[type=text][name='daily_deal_variation[value_proposition]'][value='#{@daily_deal.value_proposition}']"
          assert_select "input[type=text][name='daily_deal_variation[voucher_headline]'][value='#{@daily_deal.voucher_headline}']"
          assert_select "input[type=text][name='daily_deal_variation[value]'][value='#{@daily_deal.value}']"
          assert_select "input[type=text][name='daily_deal_variation[price]'][value='#{@daily_deal.price}']"
          assert_select "input[type=text][name='daily_deal_variation[value_proposition_subhead]'][value='#{@daily_deal.value_proposition_subhead}']"

          assert_select "input[type=text][name='daily_deal_variation[affiliate_url]']"

          # quantity do not have default values, since they delegate to the daily deal if not set.
          assert_select "input[type=text][name='daily_deal_variation[quantity]']"
          assert_select "input[type=text][name='daily_deal_variation[min_quantity]']"
          assert_select "input[type=text][name='daily_deal_variation[max_quantity]']"
          
          assert_select "select[name='daily_deal_variation[certificates_to_generate_per_unit_quantity]']"

          # barcodes
          assert_select "input[type=file][name='daily_deal_variation[bar_codes_csv]']"
          assert_select "select[name='daily_deal_variation[bar_code_encoding_format]']"
          assert_select "input[type=checkbox][name='daily_deal_variation[allow_duplicate_bar_codes]']"
          assert_select "input[type=checkbox][name='daily_deal_variation[delete_existing_unassigned_bar_codes]']"          

          assert_select "textarea[name='daily_deal_variation[terms]']", :text => /these are my terms/
          assert_select "input[type=submit][value='Save']"
        end
      end
    end
  end

  context "create" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.update_attribute(:self_serve, true)
      @valid_daily_deal_variation_attributes = Factory.attributes_for(:daily_deal_variation).except(:daily_deal)
    end

    context "without an account" do

      should "redirect to new session path" do
        post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
        assert_redirected_to new_session_path
      end
      
    end

    context "with a user account NOT associated with the publisher" do

      should "redirect to new session path" do
        login_as Factory(:user)
        post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
        assert_redirected_to new_session_path
      end

    end

    context "with a user account associated with the publisher" do

      setup do
        @user = Factory(:user, :company => @daily_deal.publisher)
      end

      context "with a publisher that is NOT setup for daily deal variations" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, false)
        end

        should "not add a new daily deal variation with valid attributes" do
          login_as @user
          assert_no_difference "DailyDealVariation.count" do
            post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
          end
          assert_template "edit"
          assert_layout "application"
        end

      end

      context "with a publisher that IS setup for daily deal variations" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
        end

        should "add a new daily deal variation with valid daily deal variation attributes" do
          login_as @user
          assert_difference "DailyDealVariation.count" do
            post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
          end
          assert_redirected_to edit_daily_deal_path(@daily_deal)
          assert flash[:notice].present?, "should assign flash message"
        end
              
      end

    end

    context "with an admin account" do

      context "with a publisher that is NOT setup for daily deal variations" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, false)
        end

        should "not add a new daily deal variation with valid attributes" do
          login_as Factory(:admin)
          assert_no_difference "DailyDealVariation.count" do
            post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
          end
          assert_template "edit"
          assert_layout "application"
        end

      end

      context "with a publisher that IS setup for daily deal variations" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
        end

        should "add a new daily deal variation with valid daily deal variation attributes" do
          login_as Factory(:admin)
          assert_difference "DailyDealVariation.count" do
            post :create, :daily_deal_id => @daily_deal.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
          end
          assert_redirected_to edit_daily_deal_path(@daily_deal)
          assert flash[:notice].present?, "should assign flash message"
        end
              
      end

    end    

  end

  context "edit" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.update_attributes(:self_serve => true, :enable_daily_deal_variations => true)
      @daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
    end

    context "without an account" do

      should "redirect to the new session path" do
        get :edit, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert_redirected_to new_session_path
      end

    end

    context "with a user account not associated with the daily deal" do

      should "redirect to the new session path" do
        login_as Factory(:user)
        get :edit, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert_redirected_to new_session_path
      end
      
    end
    
    context "with a Travelsavers deal" do
      
      setup do
        @daily_deal = Factory(:travelsavers_daily_deal)
        @user = Factory(:user, :company => @daily_deal.publisher)         
        @daily_deal.publisher.update_attributes(:self_serve => true)
        @daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal, :travelsavers_product_code => 'test123')
      end      

      
      should "display the edit template with the travelsavers_product_code" do
        login_as @user
        get :edit, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert assigns(:daily_deal), "should assign daily deal"
        assert assigns(:daily_deal_variation), "should assign daily deal variation"
        assert_template "edit"
        assert_layout "application"

        assert_select "form[action='#{daily_deal_daily_deal_variation_path(@daily_deal, @daily_deal_variation)}'][method='post']" do
          assert_select "input[type=text][name='daily_deal_variation[travelsavers_product_code]'][value=test123]"
        end 
      end   
      
      should "be visible, read-only, on a distributed deal whose source deal uses the travelsavers payment method" do
        login_as Factory :admin    
        source_daily_deal_variation = Factory(:travelsavers_daily_deal_variation)    
        source_deal = source_daily_deal_variation.daily_deal 
        distributed_publisher = Factory(:publisher, :self_serve => true, :enable_daily_deal_variations => true)
        distributed_deal = syndicate(source_deal,distributed_publisher)  
        
        get :edit, :daily_deal_id => distributed_deal.to_param, :id => source_daily_deal_variation.to_param
        assert assigns(:daily_deal).source.pay_using?(:travelsavers)        
        assert_response :success
        assert_select "input[type=text][name='daily_deal_variation[travelsavers_product_code]'][disabled=disabled]"
      end
      
      should "be visible, read-only, on a travelsavers source deal with associated purchases" do
        Factory :pending_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @daily_deal_variation
        @daily_deal.daily_deal_purchases.reload
                
        login_as @user
        get :edit, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert assigns(:daily_deal), "should assign daily deal"
        assert assigns(:daily_deal_variation), "should assign daily deal variation"
        assert_template "edit"
        assert_layout "application"
      
        assert_select "form[action='#{daily_deal_daily_deal_variation_path(@daily_deal, @daily_deal_variation)}'][method='post']" do
          assert_select "input[type=text][name='daily_deal_variation[travelsavers_product_code]'][value=test123][disabled=disabled]"
          assert_select "input[type=hidden][name='_method'][value='put']"
          assert_select "input[type=text][name='daily_deal_variation[value_proposition]']"
          assert_select "input[type=text][name='daily_deal_variation[value]']"
          assert_select "input[type=text][name='daily_deal_variation[price]']"
          assert_select "input[type=text][name='daily_deal_variation[listing]']"
          assert_select "input[type=submit][value='Save']"
        end        
      end      
    end

    context "with a user account associated with the daily deal" do

      setup do
        @user = Factory(:user, :company => @daily_deal.publisher)
      end

      should "be able to manage current publisher" do
        assert @user.can_manage?(@daily_deal.publisher)
      end

      should "display the edit template" do
        login_as @user
        get :edit, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert assigns(:daily_deal), "should assign daily deal"
        assert assigns(:daily_deal_variation), "should assign daily deal variation"
        assert_template "edit"
        assert_layout "application"

        assert_select "form[action='#{daily_deal_daily_deal_variation_path(@daily_deal, @daily_deal_variation)}'][method='post']" do
          assert_select "input[type=text][name='daily_deal_variation[travelsavers_product_code]'][value=test123]", false
          assert_select "input[type=hidden][name='_method'][value='put']"
          assert_select "input[type=text][name='daily_deal_variation[value_proposition]']"
          assert_select "input[type=text][name='daily_deal_variation[value]']"
          assert_select "input[type=text][name='daily_deal_variation[price]']"
          assert_select "input[type=text][name='daily_deal_variation[listing]']"
          assert_select "input[type=submit][value='Save']"
        end
      end
    end

    context "with an admin account" do

      should "display the edit template" do
        login_as Factory(:admin)
        get :edit, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert assigns(:daily_deal), "should assign daily deal"
        assert assigns(:daily_deal_variation), "should assign daily deal variation"
        assert_template "edit"
        assert_layout "application"

        assert_select "form[action='#{daily_deal_daily_deal_variation_path(@daily_deal, @daily_deal_variation)}'][method='post']" do
          assert_select "input[type=text][name='daily_deal_variation[travelsavers_product_code]'][value=test123]", false     
          assert_select "input[type=hidden][name='_method'][value='put']"
          assert_select "input[type=text][name='daily_deal_variation[value_proposition]']"
          assert_select "input[type=text][name='daily_deal_variation[value]']"
          assert_select "input[type=text][name='daily_deal_variation[price]']"
          assert_select "input[type=submit][value='Save']"
        end
      end

    end    

  end

  context "update" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.update_attributes(:self_serve => true, :enable_daily_deal_variations => true)
      @daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
      @valid_daily_deal_variation_attributes = Factory.attributes_for(:daily_deal_variation).except(:daily_deal)
    end

    context "without an account" do

      should "redirect to new session path" do
        put :update, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
        assert_redirected_to new_session_path
      end
      
    end

    context "with a user account NOT associated with the publisher" do

      should "redirect to new session path" do
        login_as Factory(:user)
        put :update, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
        assert_redirected_to new_session_path
      end

    end

    context "with a user account associated with the publisher" do

      setup do
        @user = Factory(:user, :company => @daily_deal.publisher)
      end

      context "with a publisher that is NOT setup for daily deal variations" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, false)
        end

        should "not update daily deal variation with valid attributes" do
          login_as @user
          put :update, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
          assert_template "edit"
          assert_layout "application"
        end

      end

      context "with a publisher that IS setup for daily deal variations" do

        setup do
          @daily_deal.publisher.update_attribute(:enable_daily_deal_variations, true)
        end

        should "add a new daily deal variation with valid daily deal variation attributes" do
          login_as @user      
          put :update, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param, :daily_deal_variation => @valid_daily_deal_variation_attributes
          assert_redirected_to edit_daily_deal_path(@daily_deal)
          assert flash[:notice].present?, "should assign flash message"
        end
              
      end

    end    

  end

  context "destroy" do

    setup do
      @daily_deal = Factory(:daily_deal)
      @daily_deal.publisher.update_attributes(:self_serve => true, :enable_daily_deal_variations => true)
      @daily_deal_variation = Factory(:daily_deal_variation, :daily_deal => @daily_deal)
    end

    context "without an account" do

      should "redirect to new session path" do
        delete :destroy, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert_redirected_to new_session_path
      end
      
    end

    context "with a user account NOT associated with the publisher" do

      should "redirect to new session path" do
        login_as Factory(:user)
        delete :destroy, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert_redirected_to new_session_path
      end

    end

    context "with a user account associated with the publisher" do

      setup do
        @user = Factory(:user, :company => @daily_deal.publisher)
      end
      
      should "delete the variation" do
        login_as @user
        assert_no_difference "DailyDealVariation.count" do
          delete :destroy, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        end
        assert_not_nil @daily_deal_variation.reload.deleted_at
        assert_not_nil flash[:notice]
        assert_redirected_to edit_daily_deal_path(@daily_deal)
      end      
    end

    context "with an admin account" do

      should "delete the variation" do
        login_as Factory(:admin)
        assert_no_difference "DailyDealVariation.count" do
          delete :destroy, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        end
        assert_not_nil @daily_deal_variation.reload.deleted_at
        assert_not_nil flash[:notice]
        assert_redirected_to edit_daily_deal_path(@daily_deal)
      end      

      
      should "handle an exception from the delete! method" do
        Factory(:captured_daily_deal_purchase, :daily_deal => @daily_deal, :daily_deal_variation => @daily_deal_variation)
        login_as Factory(:admin)
        delete :destroy, :daily_deal_id => @daily_deal.to_param, :id => @daily_deal_variation.to_param
        assert_nil     flash[:notice]
        assert_not_nil flash[:error]
        assert_redirected_to edit_daily_deal_path(@daily_deal)
      end
    end


  end
end
