require File.dirname(__FILE__) + "/../test_helper"

class DailyDealCategoriesControllerTest < ActionController::TestCase

  context "index" do
    setup do
      @publisher1 = Factory(:publisher, :enable_publisher_daily_deal_categories => true)
      @publisher2 = Factory(:publisher, :enable_publisher_daily_deal_categories => true)

      @daily_deal_category1 = Factory(:daily_deal_category, :publisher => @publisher1)
      @daily_deal_category2 = Factory(:daily_deal_category, :publisher => @publisher1)
      @daily_deal_category3 = Factory(:daily_deal_category, :publisher => @publisher1)
      @daily_deal_category4 = Factory(:daily_deal_category, :publisher => @publisher2)

      Factory(:side_daily_deal,
              :publisher => @publisher1,
              :start_at => 1.day.from_now,
              :hide_at => 20.days.from_now,
              :publishers_category => @daily_deal_category1)
      Factory(:side_daily_deal,
              :publisher => @publisher1,
              :start_at => 1.day.from_now,
              :hide_at => 20.days.from_now,
              :publishers_category => @daily_deal_category2)
      Factory(:daily_deal,
              :publisher => @publisher1,
              :start_at => 30.days.ago,
              :hide_at => 20.days.ago,
              :publishers_category => @daily_deal_category3)
    end

    should "assign categories with active deals to @daily_deal_categories" do
      Timecop.freeze(2.days.from_now) do
        get :index, :publisher_id => @publisher1.to_param
        assert_same_elements [@daily_deal_category1.id, @daily_deal_category2.id], assigns(:daily_deal_categories).map(&:id)
      end
    end

    context "PublishingGroup#enable_redirect_to_users_publisher" do
      should "redirect to the consumer's publisher daily deal categories page when they are logged in if it does not have master membership code" do
        publishing_group = Factory(:publishing_group, :label => "bcbsa", :enable_redirect_to_users_publisher => true)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :label => 'test-pub')
        other_publisher = Factory(:publisher, :publishing_group => publishing_group)
        consumer = Factory(:consumer, :publisher => publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
        login_as consumer
        get :index, :publisher_id => other_publisher.id
        assert_redirected_to publisher_daily_deal_categories_path(publisher.id)
      end


      should "redirect to the main publishers daily deal categories page because the user is not logged in or cookied" do
        publishing_group = Factory(:publishing_group, :unique_email_across_publishing_group => true, :allow_single_sign_on => true, :require_publisher_membership_codes => true, :enable_redirect_to_users_publisher => true)

        publisher = Factory(:publisher, :publishing_group => publishing_group, :label => 'test-pub', :main_publisher => true)
        master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => publisher, :master => true)

        other_publisher = Factory(:publisher, :publishing_group => publishing_group)

        get :index, :publisher_id => other_publisher.id
        assert_redirected_to publisher_daily_deal_categories_path(publisher.id)
      end

      should "not redirect to the consumer's publisher daily deal categories page when they are logged in if it does have master membership code" do

        publishing_group = Factory(:publishing_group, :unique_email_across_publishing_group => true, :allow_single_sign_on => true, :require_publisher_membership_codes => true, :enable_redirect_to_users_publisher => true)

        publisher = Factory(:publisher, :publishing_group => publishing_group, :label => 'test-pub')
        master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => publisher, :master => true)

        other_publisher = Factory(:publisher, :publishing_group => publishing_group)

        consumer = Factory(:consumer, :publisher => publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password", :publisher_membership_code => master_publisher_membership_code)

        login_as consumer
        get :index, :publisher_id => other_publisher.id

        assert_response :success
        assert_template :index
        assert_nil flash[:notice]
      end
    end
  end

  context "show" do
    context "with daily_deal_categories assigned to publisher" do
      context "given a category with deals featured in that category" do
        setup do
          @publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)

          @daily_deal_category1 = Factory(:daily_deal_category, :publisher => @publisher)
          @daily_deal_category2 = Factory(:daily_deal_category, :publisher => @publisher)

          @daily_deal1 = Factory(:side_daily_deal,
                                 :publisher => @publisher,
                                 :start_at => 5.days.from_now,
                                 :hide_at => 10.days.from_now,
                                 :featured_in_category => true,
                                 :publishers_category => @daily_deal_category1)
          @daily_deal2 = Factory(:side_daily_deal,
                                 :publisher => @publisher,
                                 :start_at => 8.days.from_now,
                                 :hide_at => 20.days.from_now,
                                 :featured_in_category => true,
                                 :publishers_category => @daily_deal_category1)
          @daily_deal3 = Factory(:side_daily_deal,
                                 :publisher => @publisher,
                                 :start_at => 7.days.from_now,
                                 :hide_at => 20.days.from_now,
                                 :featured_in_category => false,
                                 :publishers_category => @daily_deal_category1)
          @daily_deal4 = Factory(:side_daily_deal,
                                 :publisher => @publisher,
                                 :start_at => 7.days.from_now,
                                 :hide_at => 20.days.from_now,
                                 :featured_in_category => false,
                                 :publishers_category => @daily_deal_category2)
        end

        should "assign category to @daily_deal_category" do
          Timecop.freeze(9.days.from_now) do
            get :show, :id => @daily_deal_category1.to_param, :publisher_id => @publisher.to_param
            assert_equal @daily_deal_category1, assigns(:daily_deal_category)
          end
        end

        should "assign all deals in given category to @daily_deals" do
          Timecop.freeze(9.days.from_now) do
            get :show, :id => @daily_deal_category1.to_param, :publisher_id => @publisher.to_param
            assert_same_elements [@daily_deal1.id, @daily_deal2.id, @daily_deal3.id], assigns(:daily_deals).map(&:id)
          end
        end

        should "assign oldest active deal marked featured_in_category to @featured_deal" do
          Timecop.freeze(6.days.from_now) do
            get :show, :id => @daily_deal_category1.to_param, :publisher_id => @publisher.to_param
            assert_equal @daily_deal1.id, assigns(:featured_deal).id
          end

          Timecop.freeze(12.days.from_now) do
            get :show, :id => @daily_deal_category1.to_param, :publisher_id => @publisher.to_param
            assert_equal @daily_deal2.id, assigns(:featured_deal).id
          end
        end

        should "assign deals in category that are not featured for category to @side_deals" do
          Timecop.freeze(9.days.from_now) do
            get :show, :id => @daily_deal_category1.to_param, :publisher_id => @publisher.to_param
            assert_same_elements [@daily_deal2.id, @daily_deal3.id], assigns(:side_deals).map(&:id)
          end

          Timecop.freeze(11.days.from_now) do
            get :show, :id => @daily_deal_category1.to_param, :publisher_id => @publisher.to_param
            assert_equal [@daily_deal3.id], assigns(:side_deals).map(&:id)
          end
        end
      end

      context "given a category with no deals featured" do
        setup do
          @publisher = Factory(:publisher, :enable_publisher_daily_deal_categories => true)

          @daily_deal_category = Factory(:daily_deal_category, :publisher => @publisher)

          @daily_deal1 = Factory(:side_daily_deal,
                                 :publisher => @publisher,
                                 :start_at => 10.days.ago,
                                 :hide_at => 5.days.ago,
                                 :featured_in_category => false,
                                 :publishers_category => @daily_deal_category)
          @daily_deal2 = Factory(:side_daily_deal,
                                 :publisher => @publisher,
                                 :start_at => 20.days.ago,
                                 :hide_at => 5.days.ago,
                                 :featured_in_category => false,
                                 :publishers_category => @daily_deal_category)
        end

        should "assgin deal with oldest start_at date in the category to @featured_deal" do
          Timecop.freeze(7.days.ago) do
            get :show, :id => @daily_deal_category.to_param, :publisher_id => @publisher.to_param
            assert_equal @daily_deal2.id, assigns(:featured_deal).id
          end
        end

        should "assign all other deals in the category to @side_deals" do
          Timecop.freeze(7.days.ago) do
            get :show, :id => @daily_deal_category.to_param, :publisher_id => @publisher.to_param
            assert_equal [@daily_deal1.id], assigns(:side_deals).map(&:id)
          end
        end
      end
    end

    context "with daily_deal_categories assigned to publishing_group" do
      setup do
        publishing_group = Factory(:publishing_group)

        @publisher1 = Factory(:publisher, :publishing_group => publishing_group, :enable_publisher_daily_deal_categories => true)
        @publisher2 = Factory(:publisher, :publishing_group => publishing_group, :enable_publisher_daily_deal_categories => true)

        @daily_deal_category1 = Factory(:daily_deal_category, :publishing_group => publishing_group)
        @daily_deal_category2 = Factory(:daily_deal_category, :publishing_group => publishing_group)

        @daily_deal1 = Factory(:side_daily_deal,
                               :publisher => @publisher1,
                               :start_at => 5.days.from_now,
                               :hide_at => 10.days.from_now,
                               :featured_in_category => true,
                               :publishers_category => @daily_deal_category1)
        @daily_deal2 = Factory(:side_daily_deal,
                               :publisher => @publisher2,
                               :start_at => 5.days.from_now,
                               :hide_at => 10.days.from_now,
                               :featured_in_category => true,
                               :publishers_category => @daily_deal_category1)
      end

      should "assign all deals in given category under given publisher to @daily_deals" do
        Timecop.freeze(8.days.from_now) do
          get :show, :id => @daily_deal_category1.to_param, :publisher_id => @publisher1.to_param
          assert_same_elements [@daily_deal1.id], assigns(:daily_deals).map(&:id)
        end
      end
    end

    context "PublishingGroup#enable_redirect_to_users_publisher" do
      should "redirect to the consumer's publisher daily deal category page when they are logged in if it does not have master membership code" do
        publishing_group = Factory(:publishing_group, :label => "bcbsa", :enable_redirect_to_users_publisher => true)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :label => 'test-pub')
        other_publisher = Factory(:publisher, :publishing_group => publishing_group)
        consumer = Factory(:consumer, :publisher => publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password")
        daily_deal_category = Factory(:daily_deal_category, :publishing_group => publishing_group)

        login_as consumer
        get :show, :publisher_id => other_publisher.id, :id => daily_deal_category.id

        assert_redirected_to publisher_daily_deal_category_path(:publisher_id => publisher.id, :id => daily_deal_category.id)
      end

      should "redirect to the main publisher's' daily deal category page when the user is not logged in" do
        publishing_group = Factory(:publishing_group, :label => "bcbsa", :enable_redirect_to_users_publisher => true)
        publisher = Factory(:publisher, :publishing_group => publishing_group, :label => 'test-pub', :main_publisher => true)
        other_publisher = Factory(:publisher, :publishing_group => publishing_group)

        daily_deal_category = Factory(:daily_deal_category, :publishing_group => publishing_group)


        get :show, :publisher_id => other_publisher.id, :id => daily_deal_category.id

        assert_redirected_to publisher_daily_deal_category_path(:publisher_id => publisher.id, :id => daily_deal_category.id)
      end

      should "not redirect to the consumer's publisher daily deal categories page when they are logged in if it does have master membership code" do

        publishing_group = Factory(:publishing_group, :unique_email_across_publishing_group => true, :allow_single_sign_on => true, :require_publisher_membership_codes => true, :enable_redirect_to_users_publisher => true)

        publisher = Factory(:publisher, :publishing_group => publishing_group, :label => 'test-pub')
        master_publisher_membership_code = Factory(:publisher_membership_code, :publisher => publisher, :master => true)

        other_publisher = Factory(:publisher, :publishing_group => publishing_group)

        consumer = Factory(:consumer, :publisher => publisher, :email => "foobar@yahoo.com", :password => "password", :password_confirmation => "password", :publisher_membership_code => master_publisher_membership_code)
        daily_deal_category = Factory(:daily_deal_category, :publishing_group => publishing_group)

        login_as consumer
        get :show, :publisher_id => other_publisher.id, :id => daily_deal_category.id

        assert_response :success
        assert_template :show
        assert_nil flash[:notice]
      end
    end
  end

end
