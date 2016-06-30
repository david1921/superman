require File.dirname(__FILE__) + "/../../test_helper"

class CouponMailerTest < ActionMailer::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  def test_coupon_with_owning_publisher
    assert_equal 0, ActionMailer::Base.deliveries.size, "Emails delivered"
    offer = offers(:changos_buy_two_tacos)
    offer.save!
    lead = offer.leads.build(:publisher => offer.publisher, :email => "me@gmail.com", :email_me => true)
    
    CouponMailer.deliver_coupon lead
    assert_equal 1, ActionMailer::Base.deliveries.size, "Emails delivered"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["support@txt411.com"], email.from, "From: header"
    assert_equal "MySDH.com Coupons", email.friendly_from, "From: header (friendly)"
    assert_equal ["me@gmail.com"], email.to, "To: header"
    assert_equal "MySDH.com Coupons: Your Changos coupon", email.subject, "Subject: header"

    assert_equal "multipart/alternative", email.content_type, "Content-Type: header"
    assert_equal 2, email.parts.size, "Should have 2 parts"

    part = email.parts.detect { |p| p.content_type == "text/plain" }
    assert_not_nil part, "Should have text/plain part"
    assert_equal "text/plain", part.content_type, "Content-Type: of first part"
    assert_match /ANOTHER GREAT COUPON FROM MYSDH.COM/, part.body
    assert_match %r{#{offer.message}}, part.body
    assert_match /the Student Discount Handbook Austin website/, part.body

    part = email.parts.detect { |p| p.content_type == "text/html" }
    assert_not_nil part, "Should have text/html part"
    assert_equal "text/html", part.content_type, "Content-Type: of second part"
    assert_match %r{Another Great Coupon from MySDH.com}, part.body
    assert_match %r{#{offer.message}}, part.body
    assert_match %r{src="http://s3.amazonaws.com/offer-images.offers.analoganalytics.com/test/#{offer.id}/large.png"}, part.body
    assert_match /the Student Discount Handbook Austin website/, part.body
  end
  
  def test_coupon_with_non_owning_publisher
    assert_equal 0, ActionMailer::Base.deliveries.size, "Emails delivered"
    offer = offers(:changos_buy_two_tacos)
    offer.save!
    publisher = publishers(:sdreader)
    assert_not_equal publisher, offer.publisher, "Publisher should not own offer"
    lead = offer.leads.build(:publisher => publisher, :email => "me@gmail.com", :email_me => true)
    
    CouponMailer.deliver_coupon lead
    assert_equal 1, ActionMailer::Base.deliveries.size, "Emails delivered"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["support@txt411.com"], email.from, "From: header"
    assert_equal "San Diego Reader Coupons", email.friendly_from, "From: header (friendly)"
    assert_equal ["me@gmail.com"], email.to, "To: header"
    assert_equal "San Diego Reader Coupons: Your Changos coupon", email.subject, "Subject: header"

    assert_equal "multipart/alternative", email.content_type, "Content-Type: header"
    assert_equal 2, email.parts.size, "Should have 2 parts"

    part = email.parts.detect { |p| p.content_type == "text/plain" }
    assert_not_nil part, "Should have text/plain part"
    assert_equal "text/plain", part.content_type, "Content-Type: of first part"
    assert_match /ANOTHER GREAT COUPON FROM SAN DIEGO READER/, part.body
    assert_match %r{#{offer.message}}, part.body
    assert_match /the San Diego Reader website/, part.body

    part = email.parts.detect { |p| p.content_type == "text/html" }
    assert_not_nil part, "Should have text/html part"
    assert_equal "text/html", part.content_type, "Content-Type: of second part"
    assert_match %r{Another Great Coupon from San Diego Reader}, part.body
    assert_match %r{#{offer.message}}, part.body
    assert_match %r{src="http://s3.amazonaws.com/offer-images.offers.analoganalytics.com/test/#{offer.id}/large.png"}, part.body
    assert_match /the San Diego Reader website/, part.body
  end

  def test_coupon_with_blank_publisher_support_email_address
    offer = offers(:changos_buy_two_tacos)
    offer.publisher.update_attributes! :support_email_address => ""
    lead = offer.leads.build(:publisher => offer.publisher, :email => "me@gmail.com", :email_me => true)
    
    CouponMailer.deliver_coupon lead
    assert_equal 1, ActionMailer::Base.deliveries.size, "Emails delivered"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["support@txt411.com"], email.from, "From: header"
    assert_equal "MySDH.com Coupons", email.friendly_from, "From: header (friendly)"
  end
  
  def test_coupon_with_publisher_support_email_address_present
    offer = offers(:changos_buy_two_tacos)
    offer.publisher.update_attributes! :support_email_address => "MySDH.com <coupons@mysdh.com>"
    lead = offer.leads.build(:publisher => offer.publisher, :email => "me@gmail.com", :email_me => true)
    
    CouponMailer.deliver_coupon lead
    assert_equal 1, ActionMailer::Base.deliveries.size, "Emails delivered"
    email = ActionMailer::Base.deliveries.first

    assert_equal ["coupons@mysdh.com"], email.from, "From: header"
    assert_equal "MySDH.com", email.friendly_from, "From: header (friendly)"
  end
  
  def test_coupon_with_email_footer
    publisher = Factory(:publisher, {
      :publishing_group => Factory(:publishing_group, :label => "mcclatchy"),
      :label => "sacbee",
      :production_host => "findnsave.sacbee.com",
      :address_line_1 => "2100 Q Street",
      :city => "Sacramento",
      :state => "CA",
      :zip => "95816"
    })
    advertiser = Factory(:advertiser, :publisher => publisher)
    offer = Factory(:offer, :advertiser => advertiser)
    lead = Factory(:lead, :offer => offer, :publisher => publisher)
    
    coupon_mail = CouponMailer.create_coupon(lead)
    html_part = coupon_mail.parts.detect { |p| p.content_type == "text/html" }
    plain_text_part = coupon_mail.parts.detect { |p| p.content_type == "text/plain" }
    
    assert_match %r{<a href="http://findnsave.sacbee.com/">Click Here</a> for more coupons}, html_part.body, "Custom HTML coupon footer"
    assert_match %r{sign up for the Sacramento Find n Save daily deals email}, html_part.body, "Custom HTML coupon footer"

    assert_match %r{Click here for more coupons.*\n\nhttp://findnsave.sacbee.com/}, plain_text_part.body, "Custom plain-text coupon footer"
    assert_match %r{sign up for the Sacramento Find n Save daily deals email}, plain_text_part.body, "Custom plain-text coupon footer"
  end   
  
  def test_coupon_footer_with_mcclatchy_publications
    publishing_group = Factory(:publishing_group, :label => "mcclatchy")
    publishers       = {
      :sacbee => {
        :production_host  => "findnsave.sacbee.com",
        :address_line_1   => "2100 Q Street",
        :city             => "Sacramento",       
        :state            => "CA",
        :zip              => "95816"        
      },
      :bellevillenewsdemocrat => {
        :production_host  => "findnsave.bnd.com",
        :address_line_1   => "120 South Illinois",
        :city             => "Belleville",
        :state            => "IL",
        :zip              => "62220"
      },
      :modestobee => {
        :production_host  => "findnsave.modbee.com",
        :address_line_1   => "1325 H Street",
        :city             => "Modesto",
        :state            => "CA",
        :zip              => "95354"
      },
      :mercedsunstar => {
        :production_host  => "findnsave.mercedsunstar.com",
        :address_line_1   => "3033 North G Street",
        :city             => "Merced",
        :state            => "CA",
        :zip              => "95340"
      },
      :wichitaeagle => {
        :production_host  => "findnsave.kansas.com",
        :address_line_1   => "825 E. Douglas",
        :city             => "Witchita",
        :state            => "KS",
        :zip              => "67202"
      },
      :fresnobee => {
        :production_host  => "findnsave.fresnobee.com",
        :address_line_1   => "1626 E Street",
        :city             => "Fresno",
        :state            => "CA",
        :zip              => "93786"
      }
    }
    publishers.each_pair do |label, settings|
      publisher  = Factory(:publisher, settings.merge(:label => label.to_s, :publishing_group => publishing_group) )
      advertiser = Factory(:advertiser, :publisher => publisher)
      offer      = Factory(:offer, :advertiser => advertiser)
      lead       = Factory(:lead, :offer => offer, :publisher => publisher)

      coupon_mail = CouponMailer.create_coupon(lead)
      html_part = coupon_mail.parts.detect { |p| p.content_type == "text/html" }
      plain_text_part = coupon_mail.parts.detect { |p| p.content_type == "text/plain" }

      assert_match Regexp.new("<a href=\"http://#{publisher.production_host}/\">Click Here</a> for more coupons"), html_part.body, "Custom HTML coupon footer"
      assert_match Regexp.new("sign up for the #{publisher.city} Find n Save daily deals email"), html_part.body, "Custom HTML coupon footer"

      assert_match Regexp.new("Click here for more coupons.*\n\nhttp://#{publisher.production_host}/"), plain_text_part.body, "Custom plain-text coupon footer"
      assert_match Regexp.new("sign up for the #{publisher.city} Find n Save daily deals email"), plain_text_part.body, "Custom plain-text coupon footer"      
    end
  end
end
