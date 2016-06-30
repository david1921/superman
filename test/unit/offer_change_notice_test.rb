require File.dirname(__FILE__) + "/../test_helper"

class OfferChangeNoticeTest < ActiveSupport::TestCase
  def test_change_notice
    Time.expects(:now).at_least(0).returns(Time.parse("Oct 29, 2008 11:00:00"))

    publisher = publishers(:locm)
    publisher.advertisers.destroy_all
    advertiser_1 = publisher.advertisers.create!(:name => "Advertiser 1", :listing => "001")
    advertiser_2 = publisher.advertisers.create!(:name => "Advertiser 2", :listing => "002")
    
    offer_1 = advertiser_1.offers.create!(:message => "Offer 1")
    offer_2 = advertiser_2.offers.create!(:message => "Offer 2", :show_on => "Nov 1, 2008")
    offer_3 = advertiser_1.offers.create!(:message => "Offer 3", :expires_on => "Nov 2, 2008")
    offer_4 = advertiser_2.offers.create!(:message => "Offer 4", :show_on => "Nov 2, 2008", :expires_on => "Nov 30, 2008")

    Time.expects(:now).at_least(0).returns(Time.parse("Oct 30, 2008 12:34:56"))
    assert_change_rows publisher, "Oct 31, 2008", [[offer_1, "A", 2], [offer_3, "A", 2]]
    
    offer_2.update_attributes! :updated_at => "Oct 31, 2008 11:00:00"
    Time.expects(:now).at_least(0).returns(Time.parse("Oct 31, 2008 12:34:56"))
    assert_change_rows publisher, "Nov 01, 2008", [[offer_2, "A", 1]]
    
    offer_1.update_attributes! :updated_at => "Oct 31, 2008 11:00:00"
    Time.expects(:now).at_least(0).returns(Time.parse("Nov 01, 2008 12:34:56"))
    assert_change_rows publisher, "Nov 02, 2008", [[offer_1, "U", 2], [offer_4, "A", 2]]
    
    offer_3.update_attributes! :updated_at => "Nov 02, 2008 11:00:00"
    Time.expects(:now).at_least(0).returns(Time.parse("Nov 02, 2008 12:34:56"))
    assert_change_rows publisher, "Nov 03, 2008", [[offer_3, "D", 1]]
    
    Time.expects(:now).at_least(0).returns(Time.parse("Nov 03, 2008 12:34:56"))
    assert_change_rows publisher, "Nov 04, 2008", []
  end
  
  def rows_from_offers(offers)
    offers.map do |offer, change, count|
      "#{offer.advertiser.listing}\t#{offer.id}\t#{change}\t#{count}"
    end
  end
  
  def assert_change_rows(publisher, date, offers)
    change_notice = OfferChangeNotice.new(publisher, Date.parse(date))
    rows = returning([]) { |array| change_notice.generate_data { |row| array << row }}
    assert_equal rows_from_offers(offers).sort, rows.sort, "Rows for #{date}"
  end
end
