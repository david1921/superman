require File.dirname(__FILE__) + "/../test_helper"

class RoutingTest < ActionController::IntegrationTest  
  
  def test_locale_routing
    publisher = Factory(:publisher)

    route_options = {:controller => 'publishers', :action => 'deal_of_the_day', :label => publisher.label}

    I18n.default_locale = :en
    I18n.locale = :en
    assert_routing "/publishers/#{publisher.label}/deal-of-the-day", route_options
    assert_equal I18n.locale, :en

    I18n.default_locale = :es
    I18n.locale = :en
    assert_routing "/en/publishers/#{publisher.label}/deal-of-the-day", route_options.merge(:locale => 'en')

    I18n.default_locale = :en
    I18n.locale = :en
    assert_routing "/es/publishers/#{publisher.label}/deal-of-the-day", route_options.merge(:locale => 'es')
  end

  context "BCBSA vanity URLs" do
    setup do
      @labels = %w(
        AnthemBC AnthemCO AnthemCT AnthemIN AnthemKY AnthemME AnthemMO AnthemNH AnthemNV
        AnthemOH AnthemVA AnthemWI BCBSAL BCBSAR BCBSAZ BCBSDE BCBSFL BCBSGA BCBSIL
        BCBSKS BCBSLA BCBSMA BCBSMI BCBSMN BCBSMS BCBSMT BCBSNC BCBSND BCBSNE BCBSNM
        BCBSOK BCBSRI BCBSSC BCBSTN BCBSTX BCBSVT BCBSWY BSNENY BCBSWNY BCIdaho BCNEPA BSCalifornia
        BlueBenefitMA BlueChoiceSC BlueKC CapitalBC CareFirstBCBS EmpireBCBS
        ExcellusBCBS ExcellusBCBSMedicare FEP GeoBlue HMSA HealthNow HighmarkBCBS
        HighmarkBS HighmarkWV HorizonBCBS IBX IBXTPA Premera RegenceBCBSOR RegenceBCBSUT
        RegenceBS RegenceBSIdaho Triple-S WellmarkBCBS
      )
    end

    context "with host www.blue365deals.com" do
      setup do
        ActionController::TestRequest.any_instance.stubs(:host).returns("www.blue365deals.com")
      end

      should "route /:label to /publishers/:label/deal-of-the-day" do
        @labels.each do |bx_label|
          assert_recognizes({:controller => "publishers", :action => "seo_friendly_deal_of_the_day", :publisher_label => bx_label}, "/#{bx_label}")
        end
      end
    end

    context "with host not www.blue365deals.com" do
      should "route /:label to 404" do
        @labels.each do |bx_label|
          get "/#{bx_label}"
          assert_response :not_found
        end
      end
    end
  end
  
end
