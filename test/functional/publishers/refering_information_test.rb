require File.dirname(__FILE__) + "/../../test_helper"

class Publishers::ReferingInformationTest < ActionController::TestCase
  tests PublishersController

  context "show with refering information" do
    setup do
      @publisher  = Factory(:publisher)
      @daily_deal = Factory(:daily_deal, :publisher => @publisher)
    end

    context "kowabunga parameters" do
      context "with pubid parameter" do

        context "with no initial cookies[ref] or cookie[retain_until] values set" do
          setup do
            @request.cookies["ref"] = nil
            @request.cookies["retain_until"] = nil
            @request.session["first_time_visitor"] = nil
          end

          should "update the cookies[ref] to '12345'" do
            get :deal_of_the_day, :label => @publisher.label, :pubid => "12345"
            assert_equal '12345', cookies["ref"]
          end

          should "set the expires on the ref cookie so it sticks around" do
            Timecop.freeze(Time.now) do
              get :deal_of_the_day, :label => @publisher.label, :pubid => "12345"
              assert_equal 10.years.from_now.to_i, better_cookies['ref']['expires'].to_i
            end
          end

          should "set the retain_until to 30 days from now" do
            get :deal_of_the_day, :label => @publisher.label, :pubid => "12345"
            assert_equal Time.zone.now.to_date + 30.days, cookies["retain_until"].to_date
          end

          should "set the expires on the retain_until cookie so it sticks around" do
            Timecop.freeze(Time.now) do
              get :deal_of_the_day, :label => @publisher.label, :pubid => "12345"
              assert_equal 10.years.from_now.to_i, better_cookies['retain_until']['expires'].to_i
            end
          end

          should "set a session variable of first_time_visitor" do
            get :deal_of_the_day, :label => @publisher.label, :pubid => "12345"
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
              get :deal_of_the_day, :label => @publisher.label, :pubid => "12345"
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
              get :deal_of_the_day, :label => @publisher.label, :pubid => "12345"
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
          get :deal_of_the_day, :label => @publisher.label, :notpubid => "12345"
          assert_nil cookies["ref"]
        end

        should "set session[:first_time_visitor] if cookies['retain_until'] doesn't exist" do
          @request.cookies["retain_until"] = nil
          get :deal_of_the_day, :label => @publisher.label, :notpubid => "12345"
          assert session[:first_time_visitor]
        end

        should "not set session[:first_time_visitor] if cookies['retain_until'] exists with a future date" do
          @request.cookies["retain_until"] = 5.days.from_now
          get :deal_of_the_day, :label => @publisher.label, :notpubid => "12345"
          assert_nil session[:first_time_visitor]
          end

        should "not set session[:first_time_visitor] if cookies['retain_until'] exists with a past date" do
          @request.cookies["retain_until"] = 5.days.ago
          get :deal_of_the_day, :label => @publisher.label, :notpubid => "12345"
          assert_nil session[:first_time_visitor]
        end
      end

      context "with sourceid parameter" do
        setup do
          get :deal_of_the_day, :label => @publisher.label, :sourceid => "from_somewhere_special"
        end

        should "set session[src] to 'from_somewhere_special'" do
          assert_equal "from_somewhere_special", session[:src]
        end
      end

      context "without sourceid parameter" do
        setup do
          get :deal_of_the_day, :label => @publisher.label, :nottherightsourceid => "from_somewhere_special"
        end

        should "set not set session[:src]" do
          assert_nil session[:src]
        end
      end

    end
  end

end
