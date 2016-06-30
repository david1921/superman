require File.dirname(__FILE__) + "/../test_helper"

class ShoppingMallsControllerTest < ActionController::TestCase

  context "show" do

    setup do
      @publisher   = Factory(:publisher)
      @dd          = Factory(:side_daily_deal, :publisher => @publisher)
      @dd2         = Factory(:side_daily_deal, :publisher => @publisher)
      @mall_dd     = Factory(:side_daily_deal, :publisher => @publisher, :shopping_mall => true)
      @mall_dd2    = Factory(:side_daily_deal, :publisher => @publisher, :shopping_mall => true)
      @featured_dd = Factory(:daily_deal, :publisher => @publisher)
      Factory(:daily_deal) # Random deal
    end

    should "display with just a publisher in the request params" do
      get :show, :publisher_id => @publisher.label

      assert_response :success
      assert_template :show

      assert_equal @publisher, assigns(:publisher), "publisher"
      assert_equal Set.new([@featured_dd, @mall_dd, @mall_dd2]), Set.new(assigns(:daily_deals)), "daily_deals"
    end

    context "with markets" do
      setup do
        @market = Factory.create(:market, :name => "Chicago", :publisher_id => @publisher.id)
        @dd.markets << @market
      end

      should "find the market when the market label in the request is all lowercase" do
        get :show, :label => @publisher.label, :market_label => 'chicago'
        assert_response :success
        assert_equal @market, assigns(:market), "@market assignment"
      end

      should "find the market when the market label in the request is title-capped" do
        get :show, :label => @publisher.label, :market_label => 'Chicago'
        assert_response :success
        assert_equal @market, assigns(:market), "@market assignment"
      end

      should "display scoped deals with a market and a publisher in the request params, including non-shopping mall deals" do
        @market = Factory.create(:market, :name => "Cleveland", :publisher_id => @publisher.id)
        @featured_dd.markets << @market
        @mall_dd.markets << @market
        @dd2.markets << @market

        get :show, :label => @publisher.label, :market_label => 'cleveland'

        assert_response :success
        assert_template :show

        assert_equal @publisher, assigns(:publisher), "publisher"
        assert_equal [@featured_dd, @mall_dd, @dd2], assigns(:daily_deals), "daily_deals"
      end

      context "pagination" do
        should "be successful if there are enough deals to trigger pagination controls" do
          market = Factory.create(:market, :name => "Boston", :publisher_id => @publisher.id)

          5.times do
            dd = Factory(:side_daily_deal, :publisher => @publisher)
            dd.markets << market
          end

          get :show, :label => @publisher.label, :market_label => 'boston', :per_page => 2, :page => 1
          assert_response :success
          assert_template :show
        end
      end

    end

    context "with refering information" do

      context "kowabunga parameters" do
        context "with pubid parameter" do

          context "with no initial cookies[ref] or cookie[retain_until] values set" do
            setup do
              @request.cookies["ref"] = nil
              @request.cookies["retain_until"] = nil
              @request.session["first_time_visitor"] = nil
            end

            should "update the cookies[ref] to '12345'" do
              get :show, :label => @publisher.label, :pubid => "12345"
              assert_equal '12345', cookies["ref"]
            end

            should "set the expires on the ref cookie so it sticks around" do
              Timecop.freeze(Time.now) do
                get :show, :label => @publisher.label, :pubid => "12345"
                assert_equal 10.years.from_now.to_i, better_cookies['ref']['expires'].to_i
              end
            end

            should "set the retain_until to 30 days from now" do
              get :show, :label => @publisher.label, :pubid => "12345"
              assert_equal Time.zone.now.to_date + 30.days, cookies["retain_until"].to_date
            end

            should "set the expires on the retain_until cookie so it sticks around" do
              Timecop.freeze(Time.now) do
                get :show, :label => @publisher.label, :pubid => "12345"
                assert_equal 10.years.from_now.to_i, better_cookies['retain_until']['expires'].to_i
              end
            end

            should "set a session variable of first_time_visitor" do
              get :show, :label => @publisher.label, :pubid => "12345"
              assert session[:first_time_visitor]
            end
          end

          context "with initial cookie[ref] value set" do
            setup do
              @request.cookies["ref"] = "99999"
            end

            context "with retain_until in the past" do
              setup do
                @request.cookies["retain_until"] = 1.day.ago
                get :show, :label => @publisher.label, :pubid => "12345"
              end

              should "update the cookies[ref] to '12345'" do
                assert_equal '12345', cookies["ref"]
              end

              should "not set a session variable of first_time_visitor" do
                assert_nil session[:first_time_visitor]
              end
            end

            context "with retain_until in the future" do
              setup do
                @request.cookies["retain_until"] = 2.days.from_now
                get :show, :label => @publisher.label, :pubid => "12345"
              end

              should "update cookies['ref'] until Inuvo tells us what they want to do with the retain_until logic" do
                assert_equal "12345", cookies["ref"]
              end

              should "not set a session variable of first_time_visitor" do
                assert_nil session[:first_time_visitor]
              end
            end
          end
        end

        context "without pubid" do
          setup do
            @request.cookies["ref"] = nil
            @request.session["first_time_visitor"] = nil
          end

          should "not set cookies[ref]" do
            get :show, :label => @publisher.label, :notpubid => "12345"
            assert_nil cookies["ref"]
          end

          should "set session[:first_time_visitor] if cookies['retain_until'] doesn't exist" do
            @request.cookies["retain_until"] = nil
            get :show, :label => @publisher.label, :notpubid => "12345"
            assert session[:first_time_visitor]
          end

          should "not set session[:first_time_visitor] if cookies['retain_until'] exists with a future date" do
            @request.cookies["retain_until"] = 5.days.from_now
            get :show, :label => @publisher.label, :notpubid => "12345"
            assert_nil session[:first_time_visitor]
          end

          should "not set session[:first_time_visitor] if cookies['retain_until'] exists with a past date" do
            @request.cookies["retain_until"] = 5.days.ago
            get :show, :label => @publisher.label, :notpubid => "12345"
            assert_nil session[:first_time_visitor]
          end
        end

        context "with sourceid parameter" do
          setup do
            get :show, :label => @publisher.label, :sourceid => "from_somewhere_special"
          end

          should "set session[src] to 'from_somewhere_special'" do
            assert_equal "from_somewhere_special", session[:src]
          end
        end

        context "without sourceid parameter" do
          setup do
            get :show, :label => @publisher.label, :nottherightsourceid => "from_somewhere_special"
          end

          should "set not set session[:src]" do
            assert_nil session[:src]
          end
        end

      end
    end

  end

end
