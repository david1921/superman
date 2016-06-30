require File.dirname(__FILE__) + "/../../test_helper"

class MarketSelectionHelperTest < ActionView::TestCase
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
                            :state => "NY",
                            :country => country
      @publisher2 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :city => "Seattle",
                            :state => "WA",
                            :country => country
      @publisher3 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :market_name => "Dallas",
                            :state => "TX",
                            :country => country
      @publisher4 = Factory :publisher_with_address,
                            :publishing_group => nil,
                            :city => "Salem",
                            :market_name => "Portland",
                            :state => "OR"
      @publisher5 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :market_name => "Tacoma",
                            :state => "WA",
                            :launched => false,
                            :country => country
      @publisher6 = Factory :publisher_with_address,
                            :publishing_group => @publishing_group,
                            :city => "San Diego",
                            :state => "CA",
                            :exclude_from_market_selection => true
      @publisher1_path = public_deal_of_day_path(:label => @publisher1.label)
      @publisher2_path = public_deal_of_day_path(:label => @publisher2.label)
      @publisher3_path = public_deal_of_day_path(:label => @publisher3.label)
      @publisher6_path = public_deal_of_day_path(:label => @publisher6.label)
      
      @publisher1_offers_path = public_offers_path(@publisher1)
      @publisher2_offers_path = public_offers_path(@publisher2)
      @publisher3_offers_path = public_offers_path(@publisher3)
      @publisher6_offers_path = public_offers_path(@publisher6)
    end

    context "market_selection_list" do

      should "render selection when publisher has publishing_group" do
        html = ERB.new("<%= market_selection_list(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_path}']", "New York"
          assert_select "a[href='#{@publisher2_path}']", "Seattle"
        end
      end

      should "render nothing when publisher does not have publishing_group" do
        html = ERB.new("<%= market_selection_list(@publisher4) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "ul", false
      end

      should "not include publishers marked as excluded from market selection" do
        html = ERB.new("<%= market_selection_list(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_path}']", "New York"
          assert_select "a[href='#{@publisher2_path}']", "Seattle"
          assert_select "a[href='#{@publisher6_path}']", false
        end
      end

      should "accept using a publishing group instead of a publisher" do
        html = ERB.new("<%= market_selection_list(@publishing_group) %>").result(binding)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_path}']", "New York"
          assert_select "a[href='#{@publisher2_path}']", "Seattle"
        end
      end

      should "not accept anything other than publisher or publishing group" do
        assert_raise(ArgumentError) do
          html = ERB.new("<%= market_selection_list(1) %>").result(binding)
        end
      end

    end

    context "offers_market_selection_list" do
      
      should "render selection when publisher has publishing_group" do
        html = ERB.new("<%= offers_market_selection_list(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_offers_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_offers_path}']", "New York"
          assert_select "a[href='#{@publisher2_offers_path}']", "Seattle"
        end
      end

      should "render nothing when publisher does not have publishing_group" do
        html = ERB.new("<%= offers_market_selection_list(@publisher4) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "ul", false
      end

      should "not include publishers marked as excluded from market selection" do
        html = ERB.new("<%= offers_market_selection_list(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_offers_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_offers_path}']", "New York"
          assert_select "a[href='#{@publisher2_offers_path}']", "Seattle"
          assert_select "a[href='#{@publisher6_offers_path}']", false
        end
      end

      should "accept using a publishing group instead of a publisher" do
        html = ERB.new("<%= offers_market_selection_list(@publishing_group) %>").result(binding)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@publisher3_offers_path}']", "Dallas"
          assert_select "a[href='#{@publisher1_offers_path}']", "New York"
          assert_select "a[href='#{@publisher2_offers_path}']", "Seattle"
        end
      end

      should "not accept anything other than publisher or publishing group" do
        assert_raise(ArgumentError) do
          html = ERB.new("<%= offers_market_selection_list(1) %>").result(binding)
        end
      end
      
    end

    context "market_selection" do

      should "render selection when publisher has publishing_group" do
        html = ERB.new("<%= market_selection(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option", "Dallas"
          assert_select "option", "New York"
          assert_select "option", "Seattle"
        end
      end

      should "render select tag with specified field name" do
        html = ERB.new("<%= market_selection(@publisher2, :field_name => 'subscriber[market]') %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection", true
      end

      should "render blank first option when specified" do
        html = ERB.new("<%= market_selection(@publisher2, :field_name => 'subscriber[market]', :include_blank => true) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection" do
          assert_select "option", "Please select"
        end
      end

      should "allow setting the default blank entry" do
        html = ERB.new("<%= market_selection(@publisher2, :include_blank => true, :blank_text => 'City') %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option", "City"
        end
      end

      should "only show launched publishers by default" do
        html = ERB.new("<%= market_selection(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option", "Dallas"
          assert_select "option", "New York"
          assert_select "option", "Seattle"
        end
        assert_select doc.root, "select[name='subscriber[city]'].market_selection option", 3
      end

      should "show all publishers when specified" do
        html = ERB.new("<%= market_selection(@publisher2, :field_name => 'subscriber[market]', :launched_only => false) %>").result(binding)
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
        html = ERB.new("<%= market_selection(@publisher2, :field_name => 'subscriber[city]', :use_ids => true) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option[value='#{@publisher3.id}']", "Dallas"
          assert_select "option[value='#{@publisher1.id}']", "New York"
          assert_select "option[value='#{@publisher2.id}']", "Seattle"
        end
        assert_select doc.root, "select[name='subscriber[city]'].market_selection option", 3
      end

      should "render nothing when publisher does not have publishing_group" do
        html = ERB.new("<%= market_selection(@publisher4) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select", false
      end

      should "not include publishers marked as excluded from market selection" do
        html = ERB.new("<%= market_selection(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection option", 3
      end
    end

    context "market_selection_dropdown" do
      should "set values of select to publisher paths" do
        html = ERB.new("<%= market_selection_dropdown(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown" do
          assert_select "option[value='#{@publisher3_path}']", "Dallas"
        end
      end

      should "set values of select to value returned by the path_callback, when provided" do
        html = ERB.new("<%= market_selection_dropdown(@publisher2, :launched_only => true, :path_callback => lambda { |m| '/my/test/path' }) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown" do
          assert_select "option[value='/my/test/path']", "Dallas"
        end
      end

      should "set the content of each select option to the return value of market_name_callback, when provided" do
        html = ERB.new("<%= market_selection_dropdown(@publisher2, :launched_only => true, :market_name_callback => lambda { |m| 'test marketname' }) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown" do
          assert_select "option[value='#{@publisher3_path}']", "test marketname"
        end
      end

      should "only show launched publishers by default" do
        Timecop.freeze(Time.zone.local(2011, 4, 25, 12, 34, 56)) do
          html = ERB.new("<%= market_selection_dropdown(@publisher2) %>").result(binding)
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
        html = ERB.new("<%= market_selection_dropdown(@publisher4)").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select", false
      end

      should "not include publishers marked as excluded from market selection" do
        html = ERB.new("<%= market_selection_dropdown(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown option", 4
      end

      should "set the value of the blank option to the value of blank_option_string, when provided" do
        html = ERB.new("<%= market_selection_dropdown(@publisher2, :launched_only => true, :blank_option_string => 'Blank!') %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown" do
          assert_select "option", "Blank!"
        end
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
        html = ERB.new("<%= market_selection_list(@publisher1) %>").result(binding)
        doc = HTML::Document.new(html)

        assert_select doc.root, "ul.market_selection_list" do
          assert_select "a[href='#{@market2_path}']", "Dallas"
          assert_select "a[href='#{@market1_path}']", "Los Angeles"
          assert_select "a[href='#{@market3_path}']", "Yokohama"
        end
      end

      should "render nothing when publisher does not have any markets" do
        html = ERB.new("<%= market_selection_list(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "ul", false
      end
    end

    context "market_selection" do
      should "render selection when publisher has markets" do
        html = ERB.new("<%= market_selection(@publisher1) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[city]'].market_selection" do
          assert_select "option", "Dallas"
          assert_select "option", "Los Angeles"
          assert_select "option", "Yokohama"
        end
      end

      should "render nothing when publisher does not have markets" do
        html = ERB.new("<%= market_selection(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select", false
      end

      should "render select tag with specified field name" do
        html = ERB.new("<%= market_selection(@publisher1, :field_name => 'subscriber[market]') %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection", true
      end

      should "render blank first option when speficied" do
        html = ERB.new("<%= market_selection(@publisher1, :field_name => 'subscriber[market]', :include_blank => true) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select[name='subscriber[market]'].market_selection" do
          assert_select "option", "Please select"
        end
      end

      should "use market publisher's id when specified" do
        html = ERB.new("<%= market_selection(@publisher1, :field_name => 'subscriber[city]', :use_ids => true) %>").result(binding)
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
        html = ERB.new("<%= market_selection_dropdown(@publisher1) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select.market_selection_dropdown" do
          assert_select "option[value='']", "Your city"
          assert_select "option[value='#{@market2_path}']", "Dallas"
        end
      end

      should "render nothing when publisher does not have markets" do
        html = ERB.new("<%= market_selection_dropdown(@publisher2) %>").result(binding)
        doc = HTML::Document.new(html)
        assert_select doc.root, "select", false
      end
    end
  end
end
