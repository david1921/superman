require File.dirname(__FILE__) + "/factories/daily_deal_purchase"
require Rails.root.join("test/helpers/travelsavers_test_helper")

extend TravelsaversTestHelper

Factory.define :advertiser do |advertiser|
  advertiser.association          :publisher
  advertiser.sequence(:name)      { |n| "Advertiser #{n}" }
  advertiser.tagline              "Tagline"
  advertiser.voice_response_code  "2112"
  advertiser.after_build do |a|
    a.stores << Factory.build(:store, :advertiser => a) # some advertisers require a store (after_create won't work)
  end
  advertiser.after_create do |a|
    a.stores.reload
  end
end

Factory.define :advertiser_owner do |advertiser_owner|
  advertiser_owner.first_name           'beef'
  advertiser_owner.last_name            'pork'
  advertiser_owner.association          :advertiser
end

Factory.define :advertiser_without_stores, :class => Advertiser do |advertiser|
  advertiser.association          :publisher
  advertiser.sequence(:name)      { |n| "Advertiser #{n}" }
  advertiser.tagline              "Tagline"
  advertiser.voice_response_code  "2112"
end

Factory.define :advertiser_with_listing, :parent => :advertiser_without_stores do |advertiser|
  advertiser.publisher          { Factory(:publisher_allowing_listing) }
  advertiser.listing            "123456"
  advertiser.after_create do |a|
    a.stores << Factory(:store_with_listing, :advertiser => a)
  end
end

Factory.define :agreement, :class => "Syndication::Agreement" do |a|
  a.company_name             "Fighter School"
  a.title                    "Instructor"
  a.contact_name             "Viper"
  a.telephone_number         "(503) 911-4111"
  a.email                    "viper@example.com"
  a.business_terms           "1"
  a.syndication_terms        "1"
end

Factory.define :click_count do |cc|
  cc.association :publisher
  cc.count       { (rand * 20).to_i }
  cc.mode        "twitter"
  cc.created_at  Time.zone.local(2008, 9, 4, 12, 33, 4)
end

Factory.define :click_count_daily_deal, :parent => :click_count do |cc|
  cc.association :clickable, :factory => :daily_deal
end

Factory.define :click_count_offer, :parent => :click_count do |cc|
  cc.association :clickable, :factory => :offer
end

Factory.define :placement do |p|
  p.association :publisher
  p.association :offer
end

Factory.define :daily_deal_advertiser, :parent => :advertiser do |advertiser|
  advertiser.association          :publisher, :allow_daily_deals => true
end

Factory.define :consumer do |c|
  c.association           :publisher
  c.first_name            "John"
  c.last_name             "Public"
  c.sequence(:email)      { "consumer#{SecureRandom.hex(4)}@example.com" }
  c.password              "monkey"
  c.password_confirmation "monkey"
  c.agree_to_terms        true
  c.activated_at          { 4.days.ago }
  c.activation_code       "ZYXW9876"
end

# To be able to use the name instead of first and last names (setting first and last to nil in :consumer factory doesn't work because of the twisted name logic in the consumer model)
Factory.define :consumer_with_name, :class => Consumer do |c|
  c.association           :publisher
  c.name                  "John Public"
  c.sequence(:email)      { |n| "consumer_with_name#{n}@example.com" }
  c.password              "monkey"
  c.password_confirmation "monkey"
  c.agree_to_terms        true
  c.activated_at          { 4.days.ago }
  c.activation_code       "ZYXW9876"
end

Factory.define :credit do |c|
  c.association           :consumer
  c.amount                10.00
  c.origin_type           "DailyDealPurchase"
end

Factory.define :facebook_consumer, :parent => :consumer do |fb|
  fb.first_name  "John"
  fb.last_name   "Smith"
  fb.facebook_id "100001610859021"
  fb.timezone    "-7"
  fb.token       "136197326425095|603b702553b29a9ec785b31a-100001072659380|Tn4QxXKbz521M7QJt7gS05XSLcU"
end

Factory.define :billing_address_consumer, :parent => :consumer do |c|
  c.address_line_1    'somewhere'
  c.address_line_2    'special'
  c.billing_city      'brooklyn'
  c.state             'NY'
  c.country_code      'US'
  c.zip_code          '11215'
end

Factory.define :daily_deal do |deal|
  deal.association          :advertiser, :factory => :daily_deal_advertiser
  deal.publisher            { |d| d.try(:advertiser).try(:publisher) }
  deal.price                { 15.00 }
  deal.value                { |d| d.price * 2 }
  deal.value_proposition    { |d| "#{"$%.2f" % d.value} for only #{"$%.2f" % d.price}!" }
  deal.quantity             20
  deal.min_quantity         { |d| d.price < 10.00 ? 2 : 1 }
  deal.terms                "these are my terms"
  deal.description          "this is my description"
  deal.start_at             { 10.days.ago }
  deal.hide_at              { Time.zone.now.tomorrow }
  deal.short_description    "A wonderful deal"
  deal.email_voucher_redemption_message    {|d| DailyDeal.default_email_voucher_redemption_message(d.advertiser) }
  deal.voucher_steps    {|d| d.advertiser && d.advertiser.publisher.default_voucher_steps(d.advertiser.name) }
  deal.location_required    false
end

Factory.define :featured_daily_deal, :parent => :daily_deal do |deal|
  deal.side_start_at      nil
  deal.side_end_at        nil
end

Factory.define :side_daily_deal, :parent => :daily_deal do |deal|
  deal.after_build { |d|
    d.side_start_at = d.start_at
    d.side_end_at = d.hide_at
  }
end

Factory.define :daily_deal_for_syndication, :parent => :daily_deal do |deal|
  deal.available_for_syndication true
end

Factory.define :side_daily_deal_for_syndication, :parent => :daily_deal_for_syndication do |deal|
  deal.after_build { |d|
    d.side_start_at = d.start_at
    d.side_end_at = d.hide_at
  }
end

Factory.define :travelsavers_daily_deal, :parent => :daily_deal do |deal|
  deal.association                :publisher, :factory => :travelsavers_publisher
  deal.travelsavers_product_code  { "XXX-#{SecureRandom.hex(4)}"}
end

Factory.define :travelsavers_daily_deal_for_syndication, :parent => :travelsavers_daily_deal do |deal|
  deal.available_for_syndication true
end

Factory.define :distributed_daily_deal, :parent => :daily_deal do |deal|
  deal.association :source, :factory => :daily_deal_for_syndication
  deal.association :publisher
  deal.after_create do |d|
    d.source.syndicated_deals(true) # reload association so it includes self
  end
end

Factory.define :daily_deal_variation do |variation|
  variation.association :daily_deal
  variation.price { 20.00 }
  variation.value { 20.00 * 2 }  
  variation.value_proposition { |v| "#{"$%.2f" % v.value} for only #{"$%.2f" % v.price}!" }
  variation.min_quantity { 1 }
  variation.max_quantity { 3 }
end

Factory.define :travelsavers_daily_deal_variation, :parent => :daily_deal_variation do |variation|
  variation.association :daily_deal, :factory => :travelsavers_daily_deal_for_syndication
  variation.travelsavers_product_code  { "XXX-#{SecureRandom.hex(4)}"}
end

Factory.define :suggested_daily_deal do |suggested_daily_deal|
  suggested_daily_deal.association :consumer
  suggested_daily_deal.association :publisher
  suggested_daily_deal.description "Buy one large pizza, get one free"
end

Factory.define :off_platform_daily_deal, :parent => :daily_deal, :class => OffPlatformDailyDeal do |deal|
  deal.off_platform true
end

Factory.define :paypal_daily_deal, :parent => :daily_deal do |deal|
  deal.publisher { |o| o.association(:publisher, :payment_method => "paypal") }
end

Factory.define :non_voucher_daily_deal, :parent => :daily_deal do |deal|
  deal.non_voucher_deal true
  deal.price            0
  deal.min_quantity     1
  deal.max_quantity     1
end

Factory.define :off_platform_daily_deal_certificate do |cert|
 cert.association :consumer
 cert.download_url "http://example.com"
 cert.executed_at { 6.months.ago }
 cert.expires_on { 2.years.from_now.to_date }
 cert.line_item_name "$2 widget for $1"
 cert.quantity_excluding_refunds 1
 cert.redeemer_names "Steve Brown"
end

Factory.define :daily_deal_certificate do |certificate|
 certificate.association   :daily_deal_purchase
 certificate.redeemer_name  "John Public"
 certificate.sequence(:serial_number) { |n| "#{rand(100000)}" }
 certificate.actual_purchase_price { |o| o.daily_deal_purchase.price }
end

Factory.define :daily_deal_certificate_using_third_party_serial, :parent => :daily_deal_certificate do |certificate|
  certificate.serial_number_generated_by_third_party true
  certificate.sequence(:serial_number) { |n| "third-party-#{rand(100000)}" }
end

Factory.define :refunded_daily_deal_certificate, :parent => :daily_deal_certificate do |certificate|
  certificate.status "refunded"
  certificate.refunded_at {|o| o.daily_deal_purchase.refunded_at || Time.zone.now }
  certificate.refund_amount {|o| o.actual_purchase_price}
end

Factory.define :pending_daily_deal_purchase, :class => DailyDealPurchase do |ddp|
  ddp.association    :daily_deal
  ddp.consumer       { |o| o.association(:consumer, :publisher => o.daily_deal.publisher) }
  ddp.quantity       1
  ddp.payment_status "pending"
end

Factory.define :pending_non_voucher_daily_deal_purchase, :class => NonVoucherDailyDealPurchase do |ddp|
  ddp.association    :daily_deal, :factory => :non_voucher_daily_deal
  ddp.consumer       { |o| o.association(:consumer, :publisher => o.daily_deal.publisher) }
  ddp.quantity       1
  ddp.payment_status "pending"
end

# There may be a better way to do this without extra Factories
Factory.define :paypal_daily_deal_purchase, :parent => :pending_daily_deal_purchase do |ddp|
  ddp.daily_deal { |a| a.association(:paypal_daily_deal) }
end   

Factory.define :daily_deal_purchase do |ddp|
  ddp.association                             :daily_deal
  ddp.quantity                                1
  ddp.consumer                                { |o| o.association(:consumer, :publisher => o.daily_deal.publisher) }
  ddp.payment_status                          "pending"
end

Factory.define :off_platform_daily_deal_purchase do |ddp|
  ddp.association                             :daily_deal
  ddp.quantity                                1
  ddp.payment_status                          "pending"
  ddp.executed_at                             { Time.zone.now }
  ddp.gross_price                             10
  ddp.actual_purchase_price                   10
  ddp.recipient_names                          ['John Smith']
  ddp.association                             :api_user, :factory => :user
end

Factory.define :non_voucher_daily_deal_purchase, :parent => :daily_deal_purchase, :class => NonVoucherDailyDealPurchase do |ddp|
  ddp.association :daily_deal, :factory => :non_voucher_daily_deal
end

Factory.define :captured_off_platform_daily_deal_purchase, :parent => :off_platform_daily_deal_purchase do |ddp|
  ddp.after_create do |purchase|
    purchase.capture!
  end
end

Factory.define :authorized_daily_deal_purchase_base, :class => DailyDealPurchase do |ddp|
  ddp.association                             :daily_deal
  ddp.consumer                                { |o| o.association(:consumer, :publisher => o.daily_deal.publisher) }
  ddp.quantity                                1
  ddp.after_build do |purchase|
    purchase.extend(Factories::DailyDealPurchase)
  end
  ddp.after_create do |saved_ddp|
    saved_ddp.authorized_purchase_factory_after_create
  end
end

Factory.define :authorized_free_daily_deal_purchase, :class => DailyDealPurchase do |ddp|
  ddp.daily_deal                              { |o| o.association(:daily_deal, :price => 10) }
  ddp.discount                                { |o| o.association(:discount, :publisher => o.daily_deal.publisher, :amount => o.price) }
  ddp.consumer                                { |o| o.association(:consumer, :publisher => o.daily_deal.publisher) }
  ddp.quantity                                1
  ddp.payment_status                          "authorized"
  ddp.payment_status_updated_at               { Time.zone.now }
  ddp.executed_at                             { Time.zone.now }
end

Factory.define :authorized_daily_deal_purchase, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.after_build do |saved_ddp|
    unless saved_ddp.travelsavers?
      saved_ddp.daily_deal_payment = Factory.build(:braintree_payment, :daily_deal_purchase => saved_ddp)
      saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
    end
  end
end

Factory.define :authorized_daily_deal_purchase_with_sanctions_info, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.after_build do |saved_ddp|
    saved_ddp.daily_deal_payment = Factory.build(:braintree_payment_with_sanctions_info, :daily_deal_purchase => saved_ddp)
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
  end
end

Factory.define :authorized_daily_deal_paypal_purchase, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.after_create do |saved_ddp|
    saved_ddp.daily_deal_payment = Factory(:paypal_payment, :daily_deal_purchase => saved_ddp)
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
  end
end

Factory.define :pending_paypal_payment, :class => PaypalPayment do |payment|
  payment.association :daily_deal_purchase
end

Factory.define :pending_braintree_payment, :class => BraintreePayment do |payment|
  payment.association :daily_deal_purchase
end

Factory.define :daily_deal_payment_base do |payment|
  payment.association :daily_deal_purchase
  payment.sequence(:payment_gateway_id)     { |n| "sale#{SecureRandom.hex(3)}" }
  payment.amount { |o| o.daily_deal_purchase.quantity * o.daily_deal_purchase.price }
  payment.payment_at { Time.zone.now }
end

Factory.define :braintree_payment, :parent => :daily_deal_payment_base, :class => BraintreePayment do |btp|
  btp.sequence(:credit_card_last_4) { |n| "%04d" % n }
end

Factory.define :braintree_payment_with_sanctions_info, :parent => :daily_deal_payment_base, :class => BraintreePayment do |btp|
  btp.sequence(:credit_card_last_4) { |n| "%04d" % n }
  btp.sequence(:billing_first_name) { |n| "John" }
  btp.sequence(:billing_last_name) { |n| "Smith" }
  btp.sequence(:billing_address_line_1) { |n| "#{n} Jump Street" }
  btp.sequence(:billing_address_line_2) { |n| "Suite #{n}" }
  btp.sequence(:billing_city) { |n| "Ville de #{n}" }
  btp.sequence(:billing_state) { |n| Addresses::Codes::US::STATE_CODES[n % Addresses::Codes::US::STATE_CODES.length] }
  btp.sequence(:payer_postal_code) { |n| "9021#{n}" }
  btp.sequence(:name_on_card) { |n| "Pete Maverick#{n}" }
  btp.sequence(:credit_card_bin) { |n| "#{123456 + n}" }
end

Factory.define :paypal_payment, :parent => :daily_deal_payment_base, :class => PaypalPayment do |btp|
end         

Factory.define :optimal_payment, :parent => :daily_deal_payment_base, :class => OptimalPayment do |btp|
end

Factory.define :cyber_source_payment, :parent => :daily_deal_payment_base, :class => CyberSourcePayment do |csp|
  csp.sequence(:credit_card_last_4) { |n| "%04d" % n }
end

Factory.define :captured_daily_deal_purchase_with_sanctions_info, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.after_build do |saved_ddp|
    saved_ddp.daily_deal_payment = Factory.build(:braintree_payment_with_sanctions_info, :daily_deal_purchase => saved_ddp)
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
  end
end

Factory.define :captured_daily_deal_purchase, :parent => :authorized_daily_deal_purchase do |ddp|
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "captured"
    saved_ddp.create_certificates!
  end
end

Factory.define :captured_daily_deal_purchase_no_certs, :parent => :authorized_daily_deal_purchase do |ddp|
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "captured"
    saved_ddp.save!
  end
end

Factory.define :captured_non_voucher_daily_deal_purchase, :parent => :captured_daily_deal_purchase, :class => NonVoucherDailyDealPurchase do |ddp|
  ddp.association :daily_deal, :factory => :non_voucher_daily_deal
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "captured"
    saved_ddp.save!
  end
end

Factory.define :authorized_optimal_daily_deal_purchase, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "authorized"
    saved_ddp.daily_deal_payment = Factory(:optimal_payment, :daily_deal_purchase => saved_ddp)
  end
end

Factory.define :captured_optimal_daily_deal_purchase, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "captured"
    saved_ddp.daily_deal_payment = Factory(:optimal_payment, :daily_deal_purchase => saved_ddp)
    saved_ddp.create_certificates!
  end
end

Factory.define :captured_daily_deal_purchase_with_discount, :parent => :daily_deal_purchase do |ddp|
  ddp.payment_status_updated_at { Time.zone.now }

  ddp.after_build do |purchase|
    purchase.discount = Factory(:discount, :publisher => purchase.daily_deal.publisher)
    purchase.actual_purchase_price = purchase.send(:calculate_actual_purchase_price)
  end

  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "captured"
    saved_ddp.executed_at = Time.zone.now

    if saved_ddp.total_price > 0.0
      saved_ddp.daily_deal_payment = Factory(:braintree_payment, :daily_deal_purchase => saved_ddp, :amount => saved_ddp.total_price)
      saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
    else
      saved_ddp.daily_deal_payment = nil
      saved_ddp.payment_status_updated_by_txn_id = nil
    end
    saved_ddp.save!
    saved_ddp.create_certificates!
  end
end

Factory.define :refunded_daily_deal_purchase_no_certs, :parent => :authorized_daily_deal_purchase do |ddp|
  ddp.refunded_at                                 { Time.zone.now }
  ddp.sequence(:refunded_by)                      { |n| "admin#{n}" }
  ddp.sequence(:payment_status_updated_by_txn_id) { |n| "made_up_txn_#{n}" }
  ddp.actual_purchase_price { |o| o.calculate_actual_purchase_price }

  ddp.after_create do |o|
    o.payment_status = "refunded"
    tx_amount = o.price * o.quantity
    if o.refund_amount == 0
      o.refund_amount = tx_amount
      o.save!
    end
    o.daily_deal_payment.amount = tx_amount
    o.daily_deal_payment.save!
  end
end

Factory.define :refunded_daily_deal_purchase, :parent => :refunded_daily_deal_purchase_no_certs do |ddp|
  ddp.after_create do |o|
    o.create_certificates!
    o.daily_deal_certificates.each do |cert|
      cert.refund!
      cert.update_attributes(:refunded_at => cert.daily_deal_purchase.refunded_at)
    end
  end
end

Factory.define :refunded_daily_deal_purchase_with_sanctions_info, :parent => :refunded_daily_deal_purchase do |ddp|
  ddp.refunded_at                                 { Time.zone.now }
  ddp.sequence(:refunded_by)                      { |n| "admin#{n}" }
  ddp.sequence(:payment_status_updated_by_txn_id) { |n| "made_up_txn_#{n}" }
  ddp.actual_purchase_price { |o| o.calculate_actual_purchase_price }

  ddp.after_create do |o|
    o.payment_status = "refunded"
    tx_amount = o.daily_deal.price * o.quantity
    if o.refund_amount == 0
      o.refund_amount = tx_amount
      o.save!
    end
    o.daily_deal_payment.amount = tx_amount
    o.daily_deal_payment.billing_city = "London"
    o.daily_deal_payment.save!
  end
end

Factory.define :voided_daily_deal_purchase, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.daily_deal                   { |a| a.association(:daily_deal) }
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "voided"
    saved_ddp.daily_deal_payment = Factory(:paypal_payment, :daily_deal_purchase => saved_ddp, :amount => 0.0)
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
    saved_ddp.save!
    saved_ddp.create_certificates!
    saved_ddp.daily_deal_certificates.each { |c| c.update_attributes :status => "voided" }
    saved_ddp.reload
  end
end

Factory.define :voided_daily_deal_purchase_with_sanctions_info, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.daily_deal                   { |a| a.association(:daily_deal) }

  ddp.after_build do |saved_ddp|
    saved_ddp.daily_deal_payment = Factory.build(:braintree_payment_with_sanctions_info, :daily_deal_purchase => saved_ddp)
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
  end

  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "voided"
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
    saved_ddp.save!
    saved_ddp.create_certificates!
    saved_ddp.daily_deal_certificates.each { |c| c.update_attributes :status => "voided" }
    saved_ddp.reload
  end
end

Factory.define :voided_braintree_daily_deal_purchase, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.daily_deal                   { |a| a.association(:daily_deal) }
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "voided"
    saved_ddp.daily_deal_payment = Factory(:braintree_payment, :daily_deal_purchase => saved_ddp, :amount => 0.0)
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
  end
end

Factory.define :voided_optimal_payment_daily_deal_purchase, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.daily_deal                   { |a| a.association(:daily_deal) }
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "voided"
    saved_ddp.daily_deal_payment = Factory(:optimal_payment, :daily_deal_purchase => saved_ddp, :amount => 0.0)
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
  end
end


Factory.define :refunded_optimal_payment_daily_deal_purchase, :parent => :authorized_daily_deal_purchase_base do |ddp|
  ddp.daily_deal                   { |a| a.association(:daily_deal) }
  ddp.after_create do |saved_ddp|
    saved_ddp.payment_status = "refunded"
    saved_ddp.daily_deal_payment = Factory(:optimal_payment, :daily_deal_purchase => saved_ddp)
    saved_ddp.payment_status_updated_by_txn_id = saved_ddp.daily_deal_payment.payment_gateway_id
  end
end

Factory.define :discount do |discount|
  discount.association      :publisher
  discount.sequence(:code)  { |n| "CODE#{n}" }
  discount.amount           10.00
end

Factory.define :usable_discount, :parent => :discount do |discount|
  discount.first_usable_at    { 5.days.ago }
  discount.last_usable_at     { 5.days.from_now }
  discount.deleted_at         nil
end

Factory.define :soft_deleted_discount, :parent => :discount do |discount|
  discount.deleted_at         { 5.days.ago }
end

Factory.define :expired_discount, :parent => :discount do |discount|
  discount.first_usable_at    { 5.days.ago }
  discount.last_usable_at     { 2.days.ago }
  discount.deleted_at         nil
end

Factory.define :inbound_txt do |inbound_txt|
  inbound_txt.message "PIZZA 90210"
  inbound_txt.keyword "PIZZA"
  inbound_txt.subkeyword "90210"
  inbound_txt.accepted_time { Time.zone.now }
  inbound_txt.network_type "gsm"
  inbound_txt.server_address "898411"
  inbound_txt.sequence(:originator_address) { |n| "151477781#{'%02d' % n}" }
  inbound_txt.carrier "t-mobile"
end
Factory.sequence(:email) { |n| "lead#{n}@example.com" }

Factory.define :lead do |lead|
  lead.association :publisher
  lead.email_me true
  lead.email { Factory.next(:email) }
end

Factory.define :offer do |offer|
  offer.association     :advertiser
  offer.message         "this is a message"
  offer.category_names  "Retail"
end

Factory.define :category do |category|
  category.sequence(:name)  { |n| "Category #{n}" }
  category.sequence(:label) { |n| "category_#{n}" }
end

Factory.define :publisher do |publisher|
  publisher.association             :publishing_group
  publisher.sequence(:name)         { |n| "Publisher #{SecureRandom.hex(2)}-#{n}" }
  publisher.label                   { |p| p.name.downcase.gsub(' ', '') }
  publisher.theme                   "enhanced"
  publisher.production_subdomain    "sb1"
  publisher.launched                true
  publisher.payment_method          "credit"
  publisher.require_billing_address false
  publisher.google_analytics_account_ids    "UA-00000000-1"
  publisher.in_syndication_network  true
  publisher.time_zone               "Pacific Time (US & Canada)"
  publisher.federal_tax_id          "12-12121212"
  publisher.address_line_1          "1600 Pennsylvania Avenue NW"
  publisher.city                    "Washington"
  publisher.state                   "DC"
  publisher.zip                     "20500"
  publisher.country                 { Country::US }
  publisher.started_at              { Time.zone.now }
  publisher.launched_at             { Time.zone.now }
end

Factory.define :travelsavers_publisher, :parent => :publisher do |publisher|
  publisher.payment_method "travelsavers"
  publisher.enable_daily_deal_variations true
end

Factory.define :publisher_using_cybersource, :parent => :publisher do |publisher|
  publisher.payment_method "cyber_source"
  publisher.require_billing_address true
end

Factory.define :publisher_with_facebook_config, :parent => :publisher do |publisher|
  publisher.facebook_app_id 1234
  publisher.facebook_api_key "AF19"
  publisher.facebook_app_secret "sekrit"
end

Factory.define :publisher_with_yelp_credentials, :parent => :publisher do |publisher|
  publisher.yelp_consumer_key    "a-fake-key"
  publisher.yelp_consumer_secret "a-fake-secret"
  publisher.yelp_token           "a-fake-token"
  publisher.yelp_token_secret    "a-fake-token-secret"
end

Factory.define :publisher_allowing_listing, :parent => :publisher do |publisher|
  publisher.advertiser_has_listing true
end

Factory.define :publisher_with_uk_address, :class => Publisher do |publisher|
  publisher.name              "Thomsonlocal"
  publisher.address_line_1    "Thomson House"
  publisher.address_line_2    "296 Farnborough Road"
  publisher.city              "Farnborough"
  publisher.region            "Hants"
  publisher.zip               "GU14 7NU"
  publisher.phone_number      "01252 555 555"
  publisher.country           { Country::UK }
  publisher.federal_tax_id    "12-12121212"
  publisher.started_at        { Time.zone.now }
  publisher.launched_at       { Time.zone.now }
end

# This publisher will be invalid by definition, but is used for validation
# testing via Factory.build
Factory.define :publisher_without_address, :parent => :publisher do |publisher|
  publisher.address_line_1    nil
  publisher.address_line_2    nil
  publisher.city              nil
  publisher.region            nil
  publisher.zip               nil
  publisher.phone_number      nil
  publisher.country           nil
end

Factory.define :publisher_using_cyber_source, :parent => :publisher do |publisher|
  publisher.payment_method          "cyber_source"
  publisher.require_billing_address true
end

Factory.define :self_serve_publisher, :parent => :publisher do |publisher|
  publisher.self_serve true
end

Factory.define :gbp_publisher, :parent => :publisher do |publisher|
  publisher.currency_code "GBP"
end

Factory.define :cad_publisher, :parent => :publisher do |publisher|
  publisher.currency_code "CAD"
end

Factory.define :usd_publisher, :parent => :publisher do |publisher|
  publisher.currency_code "USD"
end

Factory.define :publisher_with_address, :parent => :publisher do |publisher|
  publisher.address_line_1 "1600 Pennsylvania Avenue NW"
  publisher.city "Washington"
  publisher.state "DC"
  publisher.zip "20500"
end

Factory.define :publisher_using_paychex, :parent => :publisher do |publisher|
  publisher.association :publishing_group, :factory => :publishing_group_using_paychex
end

Factory.define :publisher_membership_code do |publisher_membership_code|
  publisher_membership_code.association :publisher
  publisher_membership_code.sequence(:code) {|n| "Membership Code #{n}"}
end

Factory.define :publishing_group do |pgroup|
  pgroup.sequence(:name)       { |n| "PGroup #{SecureRandom.hex(2)}-#{n}" }
  pgroup.google_analytics_account_ids  "UA-33333333-1"
end

Factory.define :publishing_group_with_theme, :parent => :publishing_group do |pgroup|
  pgroup.label "villagevoicemedia"
end

Factory.define :publishing_group_with_yelp_credentials, :parent => :publishing_group do |pgroup|
  pgroup.yelp_consumer_key    "a-fake-key"
  pgroup.yelp_consumer_secret "a-fake-secret"
  pgroup.yelp_token           "a-fake-token"
  pgroup.yelp_token_secret    "a-fake-token-secret"
end

Factory.define :publisher_publisher_excluded_from_distribution, :class => 'PublisherPublishersExcludedFromDistribution' do |entry|
  entry.association :publisher
  entry.association :publisher_excluded_from_distribution, :factory => :publisher
end

Factory.define :publishing_group_using_paychex, :parent => :publishing_group do |publishing_group|
  publishing_group.uses_paychex true
  publishing_group.paychex_initial_payment_percentage 80.0
  publishing_group.paychex_num_days_after_which_full_payment_released 44
end

Factory.define :promotion do |p|
  p.association :publishing_group
  p.details "Buy something during this promotion and you'll get a code to apply on your next purchase"
  p.start_at { 1.week.ago }
  p.end_at { 1.week.from_now }
  p.code_prefix "ECM123"
  p.codes_expire_at { 1.month.from_now }
  p.amount "10.00"
end

Factory.define :store do |store|
  store.association    :advertiser
  store.address_line_1 "3005 South Lamar"
  store.address_line_2 "Apt 1"
  store.city           "Austin"
  store.state          "TX"
  store.zip            "78704"
  store.phone_number   "5124161500"
end

Factory.define :store_with_address, :parent => :store do |store|
  store.address_line_1 "1600 Pennsylvania Avenue NW"
  store.address_line_2 "Apt 12"
  store.city "Washington"
  store.state "DC"
  store.zip "20500"  
end

Factory.define :store_with_listing, :parent => :store_with_address do |store|
  store.sequence(:listing)      { |n| "1234#{n}" }
end

Factory.define :daily_deal_purchase_recipient do |r|
  r.association    :daily_deal_purchase
  r.name           "Sam Jackson"
  r.address_line_1 "345 Killingsworth"
  r.city           "Portland"
  r.state          "OR"
  r.zip            "97211"
end

Factory.define :subscriber do |subscriber|
  subscriber.association           :publisher
  subscriber.association           :subscriber_referrer_code
  subscriber.sequence(:email)      { |n| "subscriber#{n}@example.com" }
  subscriber.mobile_number         "503-123-4567"
  subscriber.zip_code              "97214"
  subscriber.name                  "John Subscriber"
  subscriber.age                   32
  subscriber.gender                'm'
  subscriber.city                  'Los Angeles'
  subscriber.referral_code         'abc123'
end

Factory.define :user_without_company, :class => User do |user|
  user.sequence(:login)       { |n| "user#{n}" }
  user.sequence(:name)        { |n| "first#{n} last#{n}" }
  user.sequence(:email)       { |n| "user#{n}@test.com" }
  user.salt                   "7e3041ebc2fc05a40c60028e2c4901a81035d3cd"
  user.crypted_password       "26f93052126388fc98dde23bcf96ccdb3a73848a" # test
  user.created_at             { 1.day.ago }
end

Factory.define :user, :parent => :user_without_company do |user|
  user.after_create do |saved_user|
    unless saved_user.company.present?
      saved_user.user_companies << UserCompany.new(:company => Factory(:publisher))
    end
  end
end

Factory.define :syndication_user, :parent => :user do |user|
  user.association :company, :factory => :self_serve_publisher
  user.allow_syndication_access true
end

Factory.define :bespoke_admin, :parent => :user_without_company do |user|
  user.after_create do |saved_user|
    saved_user.user_companies.create(:company => Publisher.find_by_label('bespoke') || Factory(:publisher, :label => 'bespoke', :self_serve => true))
  end
end

Factory.define :admin, :class => User do |user|
  user.login                  "new_aaron"
  user.name                   "Aaron"
  user.email                  "aaron@example.com"
  user.salt                   "da4b9237bacccdf19c0760cab7aec4a8359010b0"
  user.crypted_password       "e7d67cc8d2f0aa3f7834e3894ac809b086d7116c" # monkey
  user.created_at             { 1.day.ago.to_s(:db) }
  user.admin_privilege        User::FULL_ADMIN
end

Factory.define :restricted_admin, :parent => :admin do |user|
  user.admin_privilege        User::RESTRICTED_ADMIN
  user.sequence(:login)       { |n| "restricted#{n}" }
end

Factory.define :gift_certificate do |gift_certificate|
  gift_certificate.association                :advertiser
  gift_certificate.message                    "You will love me always"
  gift_certificate.terms                      "forever"
  gift_certificate.value                      10
  gift_certificate.price                      5
  gift_certificate.number_allocated           12
  gift_certificate.show_on                    { 1.day.from_now.to_s(:db) }
  gift_certificate.physical_gift_certificate  false
  gift_certificate.description                "diamond ring"
  gift_certificate.handling_fee               1
  gift_certificate.collect_address            false
end

Factory.define :purchased_gift_certificate do |purchased_gift_certificate|
  purchased_gift_certificate.association           :gift_certificate
  purchased_gift_certificate.redeemed              false
  purchased_gift_certificate.paypal_payment_date   "14:18:05 Jan 14, 2010 PST"
  purchased_gift_certificate.sequence(:paypal_txn_id)         { |n| "PayPal-#{n}" }
  purchased_gift_certificate.sequence(:paypal_invoice)        { |n| "Pay up for the #{n.ordinalize} time!!" }
  purchased_gift_certificate.paypal_payment_gross  { |pgc| pgc.gift_certificate.price + pgc.gift_certificate.handling_fee }
  purchased_gift_certificate.paypal_payer_email    "paypalcustomer@yahoo.com"
  purchased_gift_certificate.payment_status         "completed"
  purchased_gift_certificate.paypal_address_street  "100 Test Road"
  purchased_gift_certificate.paypal_address_city    "Vancouver"
  purchased_gift_certificate.paypal_address_state   "BC"
  purchased_gift_certificate.paypal_address_zip     "V6G3H7"
end

Factory.define :refunded_gift_certificate, :parent => :purchased_gift_certificate do |purchased_gift_certificate|
  purchased_gift_certificate.payment_status "refunded"
end

Factory.define :subscriber_referrer_code do |s|
end

Factory.define :publisher_zip_code do |pzc|
  pzc.association :publisher
  pzc.sequence(:zip_code) { |n| 10000 + n }
end

Factory.define :market_zip_code do |mzc|
  mzc.association :market
  mzc.state_code "CA"
  mzc.sequence(:zip_code) { |n| 10000 + n }
end

Factory.define :affiliate do |a|
  a.association            :publisher
  a.sequence(:login)       { |n| "user#{n}" }
  a.sequence(:name)        { |n| "first#{n} last#{n}" }
  a.sequence(:email)       { |n| "user#{n}@test.com" }
  a.salt                   "da4b9237bacccdf19c0760cab7aec4a8359010b0"
  a.crypted_password       "e7d67cc8d2f0aa3f7834e3894ac809b086d7116c" # monkey
  a.created_at             { 1.day.ago.to_s(:db) }
end

Factory.define :country, :class => Country do |c|
end

Factory.define :affiliate_placement do |ap|
  ap.association :placeable, :factory => :daily_deal
  ap.association :affiliate, :factory => :publisher
end

Factory.define :daily_deal_category do |cat|
  cat.sequence(:name) { |n| "Category #{n}" }
  cat.abbreviation "SG"
end

Factory.define :market do |market|
  market.association :publisher, :factory => :publisher
  market.sequence(:name) { |n| "San Diego #{"%03d" % n}" }
  market.sequence(:google_analytics_account_ids) { |n| "UA-11111111-#{n}" }
end

Factory.define :job do |job|
  job.association :publisher
  job.key "my_job"
  job.started_at { Time.zone.now }
end

Factory.define :finished_job, :parent => :job do |job|
  job.finished_at { Time.zone.now }
end

Factory.define :zip_code, :class => ZipCode do |zip|
end

Factory.define :push_notification_device do |pnd|
  pnd.association :publisher
  pnd.token       { SecureRandom.hex(32).upcase }
end

Factory.define :third_party_deals_api_config, :class => ThirdPartyDealsApi::Config do |c|
  c.api_username "test-api-username"
  c.api_password "test-api-password"
  c.voucher_serial_numbers_url "https://test.url/serial_numbers"
  c.voucher_status_change_url "https://test.url/voucher_status_change"
  c.association :publisher
end

Factory.define :sweepstake do |sweepstake|
  sweepstake.association        :publisher
  sweepstake.value_proposition  "Win VIP Package to Six Flags"
  sweepstake.description        "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Etiam sit amet elit vitae arcu interdum ullamcorper. Nullam ultrices, nisi quis scelerisque convallis, augue neque tempor enim, et mattis justo nibh eu elit."
  sweepstake.terms              "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Etiam sit amet elit vitae arcu interdum ullamcorper. Nullam ultrices, nisi quis scelerisque convallis, augue neque tempor enim, et mattis justo nibh eu elit."
  sweepstake.official_rules     "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Etiam sit amet elit vitae arcu interdum ullamcorper. Nullam ultrices, nisi quis scelerisque convallis, augue neque tempor enim, et mattis justo nibh eu elit."
  sweepstake.featured           false
  sweepstake.start_at           { 2.days.ago }
  sweepstake.hide_at            { 3.days.from_now }
end

Factory.define :sweepstake_entry do |entry|
  entry.association :sweepstake
  entry.association :consumer
  entry.is_an_adult "1"
  entry.agree_to_terms "1"
  entry.phone_number "1-206-927-1233"
end

Factory.define :api_activity_log do |log_entry|
  log_entry.api_name "unknown"
  log_entry.api_activity_label "unknown"
  log_entry.request_initiated_by_us true
  log_entry.request_url "http://example.com"
  log_entry.request_body %Q{\
<?xml version="1.0" encoding="UTF-8"?>
<serial_number_request listing="SERIAL-NUM-XML" purchase_id="#{ActiveSupport::SecureRandom.hex(16)}" xmlns="http://analoganalytics.com/api/third_party_deals/purchases">
<quantity>#{ rand(10) }</quantity>
</serial_number_request>}
end

Factory.define :daily_deal_order do |ddo|
  ddo.association :consumer
end

Factory.define :daily_deal_with_market, :parent => :daily_deal do |ddm|
  ddm.market_ids           [13]
end

Factory.define :manageable_publisher do |mp|
  mp.association :publisher
  mp.association :user
end

Factory.define :daily_deal_payment do |ddpay|
  ddpay.association :daily_deal_purchase
  ddpay.payment_at  { Time.zone.now }
  ddpay.after_create do |saved_ddpay|
    saved_ddpay.update_attribute :amount, saved_ddpay.daily_deal_purchase.actual_purchase_price
  end
end

Factory.define :plan do |plan|
  plan.association :publisher
  plan.sequence(:name) {|n| "Plan #{n}"}
  plan.participating true
  plan.sequence(:label) {|n| "plan#{n}"}
  plan.uses_alternate_organization_logo false
end

Factory.define :plan_prefix do |plan_prefix|
  plan_prefix.association :plan
  plan_prefix.sequence(:prefix) {|n| "Plan Prefix #{n}"}
end

Factory.define :platform_revenue_sharing_agreement, :class => "Accounting::PlatformRevenueSharingAgreement" do |rsa|
  rsa.association                               :agreement, :factory => :publishing_group
  rsa.effective_date                            { Time.zone.now }
  rsa.platform_fee_gross_percentage             5
  rsa.credit_card_fee_source                    'fixed_amount'
  rsa.credit_card_fee_fixed_amount              0.25
end

Factory.define :syndication_revenue_sharing_agreement, :class => "Accounting::SyndicationRevenueSharingAgreement" do |rsa|
  rsa.association                               :agreement, :factory => :publishing_group
  rsa.effective_date                            { Time.zone.now }
  rsa.syndication_fee_gross_percentage          13
  rsa.syndication_fee_net_percentage            7
  rsa.credit_card_fee_source                    'fixed_amount'
  rsa.credit_card_fee_fixed_amount              0.33
  rsa.approved                                  true
end

Factory.define :syndication_revenue_sharing_agreement_unapproved, :parent => :syndication_revenue_sharing_agreement do |rsa|
  rsa.approved                                  false
end

Factory.define :accountant, :class => User do |user|
  user.login                      "new_jon"
  user.name                       "Jon"
  user.email                      "jon@example.com"
  user.salt                       "da4b9237bacccdf19c0760cab7aec4a8359010b0"
  user.crypted_password           "e7d67cc8d2f0aa3f7834e3894ac809b086d7116c" # monkey
  user.created_at                 { 1.day.ago.to_s(:db) }
  user.has_accountant_privilege   true
  user.admin_privilege            User::FULL_ADMIN
end

Factory.define :user_company do |uc|
  uc.association :user
  uc.association :company
end

Factory.define :accountant_with_approver_privilege, :parent => :accountant do |accountant|
  accountant.has_fee_sharing_agreement_approver_privilege   true
end

Factory.define :syndication_net_revenue_split, :class => "DailyDeals::SyndicationRevenueSplit" do |srs|
  srs.revenue_split_type                        "net"
  srs.merchant_net_percentage                   65.0
  srs.source_net_percentage_of_remaining        30.0
  srs.distributor_net_percentage_of_remaining   40.0
  srs.aa_net_percentage_of_remaining            30.0
end

Factory.define :syndication_gross_revenue_split, :class => "DailyDeals::SyndicationRevenueSplit" do |srs|
  srs.revenue_split_type            "gross"
  srs.source_gross_percentage        20.0
  srs.merchant_gross_percentage      30.0
  srs.distributor_gross_percentage   40.0
  srs.aa_gross_percentage            10.0
end

Factory.define :yelp_business do |yelp_business|
  yelp_business.sequence(:name)    {|n| "Yelp Business #{n}"}
  yelp_business.sequence(:yelp_id) {|n| "business-#{n}"}
  yelp_business.url                {|d| "http://yelp.com/biz/#{d.yelp_id}"}
  yelp_business.rating_image_url   "http://yelp.com/images/rating_4_stars.jpg"
  yelp_business.average_rating     4.5
  yelp_business.review_count       201
end

Factory.define :https_only_host do |https_host|
  https_host.sequence(:host)  { |n| "example#{n}.com" }
end

Factory.define :bar_code do |bc|
  bc.sequence(:code) { |n| ("1234567890123456".to_i + n).to_s }
  bc.assigned false
end

Factory.define :third_party_purchases_api_config do |c|
  c.callback_username "callback_username"
  c.callback_password "callback_password"
  c.callback_url "https://callback.url"
  c.association :user
end

Factory.define :address do |c|
  c.address_line_1 'somewhere'
  c.address_line_2 'special'
  c.city 'brooklyn'
  c.state 'NY'
  c.country { Country::US }
  c.zip '11215'
end

Factory.define :suspected_fraud do |sf|
  sf.association :suspect_daily_deal_purchase, :factory => :daily_deal_purchase
  sf.association :matched_daily_deal_purchase, :factory => :daily_deal_purchase
end

Factory.define :scheduled_mailing do |m|
  m.association :publisher
  m.mailing_date 1.day.from_now
  m.mailing_name "analog-factory"
  m.remote_mailing_id "some id"
end

Factory.define :travelsavers_booking do |tb|
  tb.association :daily_deal_purchase, :factory => :travelsavers_daily_deal_purchase
  tb.sequence(:book_transaction_id) { |n| "XXX-#{n}" }
  tb.booking_status nil
  tb.payment_status nil
end

Factory.define :successful_travelsavers_booking, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_success.xml"))
  end
end

Factory.define :successful_travelsavers_booking_without_next_steps, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_success_without_next_steps.xml"))
  end
end

Factory.define :successful_travelsavers_booking_with_failed_payment, :parent => :travelsavers_booking do |tb|
  tb.association(:daily_deal_purchase, :factory => :travelsavers_authorized_daily_deal_purchase)
  tb.booking_status TravelsaversBookings::Statuses::BookingStatus::SUCCESS
  tb.payment_status TravelsaversBookings::Statuses::PaymentStatus::FAIL
end

Factory.define :pending_travelsavers_booking, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_pending.xml"))
  end
end

Factory.define :travelsavers_booking_with_validation_errors, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_validation_errors.xml"))
  end
end

Factory.define :travelsavers_booking_with_sold_out_error, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_sold_out.xml"))
  end
end

Factory.define :travelsavers_booking_with_vendor_booking_errors, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_booking_errors.xml"))
  end
end

Factory.define :successful_travelsavers_booking_with_pending_payment, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_booking_success_payment_pending.xml"))
  end
end

Factory.define :travelsavers_booking_with_price_mismatch_error, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_price_mismatch.xml"))
  end
end


Factory.define :travelsavers_booking_with_unknown_errors, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_status_unknown.xml"))
  end
end

Factory.define :travelsavers_booking_with_invalid_post_certificate, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_invalid_post_certificate.xml"))
  end
end

Factory.define :travelsavers_booking_with_fixable_booking_errors, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_fixable_booking_errors.xml"))
  end
end

Factory.define :travelsavers_booking_with_vendor_retrieval_errors, :parent => :travelsavers_booking do |f|
  f.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_vendor_booking_retrieval_errors.xml"))
  end
end

Factory.define :travelsavers_daily_deal_purchase, :parent => :daily_deal_purchase do |ddp|
  ddp.association :daily_deal, :factory => :travelsavers_daily_deal
end

Factory.define :travelsavers_captured_daily_deal_purchase, :parent => :captured_daily_deal_purchase do |ddp|
  ddp.association :daily_deal, :factory => :travelsavers_daily_deal
end

Factory.define :travelsavers_authorized_daily_deal_purchase, :parent => :authorized_daily_deal_purchase do |ddp|
  ddp.association :daily_deal, :factory => :travelsavers_daily_deal
end

Factory.define :travelsavers_pending_daily_deal_purchase, :parent => :pending_daily_deal_purchase do |ddp|
  ddp.association :daily_deal, :factory => :travelsavers_daily_deal
end

Factory.define :travelsavers_refunded_daily_deal_purchase, :parent => :refunded_daily_deal_purchase do |ddp|
  ddp.association :daily_deal, :factory => :travelsavers_daily_deal
end

Factory.define :cancelled_travelsavers_booking_with_payment_status_unknown, :parent => :travelsavers_booking do |tb|
  tb.after_create do |booking|
    update_ts_booking_from_xml_file(
      booking, Rails.root.join("test/unit/travelsavers/data/book_transaction_cancelled_booking_with_payment_unknown.xml"))
  end
end

Factory.define :recipient do |r|
  r.name           "Sam Jackson"
  r.address_line_1 "345 Killingsworth"
  r.city           "Portland"
  r.state          "OR"
  r.zip            "97211"
end

Factory.define :credit_card do |cc|
  cc.token                    "abc123"
  cc.card_type                "Visa"
  cc.bin                      "123456"
  cc.last_4                   "9876"
  cc.billing_first_name       "John"
  cc.billing_last_name        "Smith"
  cc.billing_country_code     "US"
  cc.billing_address_line_1   "123 Fake Street"
  cc.billing_address_line_2   "Apartment 4"
  cc.billing_city             "Portland"
  cc.billing_state            "OR"
  cc.billing_postal_code      "97210"
  cc.expiration_date          "05/2016"
end

Factory.define :paypal_subscription_notification do |psn|
  psn.paypal_mc_amount3 "23.99"
  psn.paypal_payer_email "jay@example.com"
  psn.paypal_txn_type "subscr_signup"
end

Factory.define :note do |n|
  n.association :notable, :factory => :advertiser
  n.association :user, :factory => :user
  n.text "I am a note!"
end

Factory.define :new_silverpop_recipient do |r|
  r.association :consumer, :factory => :consumer

end

Factory.define :silverpop_list_move do |ml|
  ml.association :consumer, :factory => :consumer
end

Factory.define :publisher_daily_deal_purchase_total do |p|
  p.sequence(:publisher_label) { |x| "Publisher_label#{x}" }
  p.total 1
  p.date Time.zone.parse("20121221").to_date
end
