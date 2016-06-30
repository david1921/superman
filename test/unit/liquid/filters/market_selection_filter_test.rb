require File.dirname(__FILE__) + "/../../../test_helper"

class MarketSelectionFilterTest < ActiveSupport::TestCase
  include ActionController::Assertions::SelectorAssertions
  include ActionController::UrlWriter
  include MarketSelectionHelper

  context "market selection filters given publishers as markets" do
    setup do
      @publishing_group = Factory :publishing_group
      country = Country::US
      @publisher1 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :city => "New York",
                            :country => country
      @publisher2 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :city => "Seattle",
                            :country => country
      @publisher3 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :market_name => "Dallas",
                            :country => country
      @publisher4 = Factory :publisher_with_address,
                            :publishing_group => nil,
                            :city => "Salem",
                            :market_name => "Portland"
      @publisher5 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :market_name => "Tacoma",
                            :launched => false,
                            :country => country
      @publisher6 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :city => "San Diego",
                            :exclude_from_market_selection => true
      @publisher1_path = public_deal_of_day_path(:label => @publisher1.label)
      @publisher2_path = public_deal_of_day_path(:label => @publisher2.label)
      @publisher3_path = public_deal_of_day_path(:label => @publisher3.label)
      @publisher6_path = public_deal_of_day_path(:label => @publisher6.label)
    end

    context "market_selection_list" do

      should "render selection when publisher has publishing_group" do
        html = Liquid::Template.parse("{{ publisher | market_selection_list }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_path}']", "New York"
          assert_select "a[href='#{@publisher2_path}']", "Seattle"
        end
      end
      
      should "render nothing when publisher does not have publishing_group" do
        html = Liquid::Template.parse("{{ publisher | market_selection_list }}").render("publisher" => @publisher4)
        doc = HTML::Document.new(html)
        assert_select doc.root, "ul", false
      end
      
      should "not include publishers marked as excluded from market selection" do
        html = Liquid::Template.parse("{{ publisher | market_selection_list }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_path}']", "New York"
          assert_select "a[href='#{@publisher2_path}']", "Seattle"
          assert_select "a[href='#{@publisher6_path}']", false
        end
      end
      
      should "accept using a publishing group instead of a publisher" do
        html = Liquid::Template.parse("{{ publishing_group | market_selection_list }}").render("publishing_group" => @publishing_group)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_path}']", "New York"
          assert_select "a[href='#{@publisher2_path}']", "Seattle"
        end
      end
      
      should "not accept anything other than publisher or publishing group" do
        assert_raise(ArgumentError) do
          Liquid::Template.parse("{{ publisher | market_selection_list }}").render("publisher" => 1)
        end
      end
      
    end
    
    context "market_selection" do

      should "render selection when publisher has publishing_group" do
        html = Liquid::Template.parse("{{ publisher | market_selection }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option", "Dallas"
          assert_select "option", "New York"
          assert_select "option", "Seattle"
        end
      end

      should "render select tag with specified field name" do
        html = Liquid::Template.parse("{{ publisher | market_selection: 'subscriber[market]' }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection", true
      end
      
      should "render blank first option when specified" do
        html = Liquid::Template.parse("{{ publisher | market_selection: 'subscriber[market]', true }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection" do
          assert_select "option", "Please select"
        end
      end
      
      should "only show launched publishers by default" do
        html = Liquid::Template.parse("{{ publisher | market_selection }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option", "Dallas"
          assert_select "option", "New York"
          assert_select "option", "Seattle"
        end
        assert_select doc.root, "select[name='subscriber[city]'].market_selection option", 3
      end

      should "show all publishers when specified" do
        html = Liquid::Template.parse("{{ publisher | market_selection: 'subscriber[market]', false, false }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection" do
          assert_select "option", "Dallas"
          assert_select "option", "New York"
          assert_select "option", "Seattle"
          assert_select "option", "Tacoma"
        end
        assert_select doc.root, "select[name='subscriber[market]'].market_selection option", 4
      end

      should "use market publisher's id when specified" do
        html = Liquid::Template.parse("{{ publisher | market_selection: 'subscriber[city]', false, true, true }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option[value='#{@publisher3.id}']", "Dallas"
          assert_select "option[value='#{@publisher1.id}']", "New York"
          assert_select "option[value='#{@publisher2.id}']", "Seattle"
        end
        assert_select doc.root, "select[name='subscriber[city]'].market_selection option", 3
      end

      should "render nothing when publisher does not have publishing_group" do
        html = Liquid::Template.parse("{{ publisher | market_selection }}").render("publisher" => @publisher4)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select", false
      end

      should "not include publishers marked as excluded from market selection" do
        html = Liquid::Template.parse("{{ publisher | market_selection }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection option", 3
      end
    end

    context "market_selection_dropdown" do
      should "set values of select to publisher paths" do
        html = Liquid::Template.parse("{{ publisher | market_selection_dropdown }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown" do
          assert_select "option[value='#{@publisher3_path}']", "Dallas"
        end
      end
      
      should "only show launched publishers by default" do
        Timecop.freeze(Time.zone.local(2011, 4, 25, 12, 34, 56)) do
          html = Liquid::Template.parse("{{ publisher | market_selection_dropdown }}").render("publisher" => @publisher2)
          doc = HTML::Document.new(html)
          assert_select doc.root, "select.market_selection_dropdown" do
            assert_select "option", "Your city"
            assert_select "option", "Dallas"
            assert_select "option", "New York"
            assert_select "option", "Seattle"
          end
          assert_select doc.root, "select.market_selection_dropdown option", 4
        end
      end

      should "render nothing when publisher does not have publishing_group" do
        html = Liquid::Template.parse("{{ publisher | market_selection_dropdown }}").render("publisher" => @publisher4)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select", false
      end

      should "not include publishers marked as excluded from market selection" do
        html = Liquid::Template.parse("{{ publisher | market_selection_dropdown }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown option", 4
      end

    end

  end
  
  context "market selection filters using publisher markets" do
    setup do
      @publisher1 = Factory(:publisher)
      @publisher2 = Factory(:publisher, :publishing_group => nil)

      @market1 = Factory(:market, :publisher => @publisher1, :name => "Los Angeles")
      @market2 = Factory(:market, :publisher => @publisher1, :name => "Dallas")
      @market3 = Factory(:market, :publisher => @publisher1, :name => "Yokohama")

      @market1_path = public_deal_of_day_for_market_path(@publisher1.label, @market1.label)
      @market2_path = public_deal_of_day_for_market_path(@publisher1.label, @market2.label)
      @market3_path = public_deal_of_day_for_market_path(@publisher1.label, @market3.label)
    end

    context "market_selection_list" do
      should "render a list of markets with links to their deal pages" do
        html = Liquid::Template.parse("{{ publisher | market_selection_list }}").render("publisher" => @publisher1)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@market2_path}']", "Dallas"
          assert_select "a[href='#{@market1_path}']", "Los Angeles"
          assert_select "a[href='#{@market3_path}']", "Yokohama"
        end
      end

      should "render nothing when publisher does not have any markets" do
        html = Liquid::Template.parse("{{ publisher | market_selection_list }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "ul", false
      end
    end

    context "market_selection" do
      should "render selection when publisher has markets" do
        html = Liquid::Template.parse("{{ publisher | market_selection }}").render("publisher" => @publisher1)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option", "Dallas"
          assert_select "option", "Los Angeles"
          assert_select "option", "Yokohama"
        end
      end

      should "render nothing when publisher does not have markets" do
        html = Liquid::Template.parse("{{ publisher | market_selection }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select", false
      end

      should "render select tag with specified field name" do
        html = Liquid::Template.parse("{{ publisher | market_selection: 'subscriber[market]' }}").render("publisher" => @publisher1)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection", true
      end
      
      should "render blank first option when speficied" do
        html = Liquid::Template.parse("{{ publisher | market_selection: 'subscriber[market]', true }}").render("publisher" => @publisher1)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection" do
          assert_select "option", "Please select"
        end
      end
      
      should "use market publisher's id when specified" do
        html = Liquid::Template.parse("{{ publisher | market_selection: 'subscriber[city]', false, true, true }}").render("publisher" => @publisher1)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option[value='#{@market2.id}']", "Dallas"
          assert_select "option[value='#{@market1.id}']", "Los Angeles"
          assert_select "option[value='#{@market3.id}']", "Yokohama"
        end
        assert_select doc.root, "select[name='subscriber[city]'].market_selection option", 3
      end

    end

    context "market_selection_dropdown" do
      should "set values of select to publisher paths" do
        html = Liquid::Template.parse("{{ publisher | market_selection_dropdown }}").render("publisher" => @publisher1)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown" do
          assert_select "option[value='']", "Your city"
          assert_select "option[value='#{@market2_path}']", "Dallas"
        end
      end

      should "render nothing when publisher does not have markets" do
        html = Liquid::Template.parse("{{ publisher | market_selection_dropdown }}").render("publisher" => @publisher2)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select", false
      end
    end
  end
end

