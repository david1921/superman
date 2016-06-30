# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120828190156) do

  create_table "addresses", :force => true do |t|
    t.integer  "country_id"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone_number"
    t.float    "longitude"
    t.float    "latitude"
    t.string   "region"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "advertiser_owners", :force => true do |t|
    t.integer  "advertiser_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "home_postal_code"
    t.string   "home_address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "advertiser_owners", ["advertiser_id"], :name => "index_advertiser_owners_on_advertiser_id"

  create_table "advertiser_signups", :force => true do |t|
    t.string   "email"
    t.integer  "advertiser_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "advertiser_signups", ["user_id"], :name => "index_advertiser_signups_on_user_id"

  create_table "advertiser_translations", :force => true do |t|
    t.integer  "advertiser_id"
    t.string   "locale"
    t.string   "tagline"
    t.string   "website_url"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "advertiser_translations", ["advertiser_id"], :name => "index_advertiser_translations_on_advertiser_id"

  create_table "advertisers", :force => true do |t|
    t.string   "tagline_TEMP"
    t.string   "voice_response_code"
    t.integer  "lock_version",                                                   :default => 0
    t.integer  "int",                                                            :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "coupon_limit"
    t.string   "name_TEMP",                                                      :default => "",    :null => false
    t.string   "landing_page"
    t.string   "coupon_clipping_modes"
    t.string   "call_phone_number"
    t.string   "website_url_TEMP"
    t.string   "email_address"
    t.string   "google_map_url"
    t.integer  "publisher_id"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.integer  "logo_width"
    t.integer  "logo_height"
    t.datetime "logo_updated_at"
    t.string   "listing"
    t.integer  "active_coupon_limit"
    t.integer  "active_txt_coupon_limit"
    t.string   "txt_keyword_prefix"
    t.integer  "logo_facebook_width"
    t.integer  "logo_facebook_height"
    t.boolean  "paid",                                                           :default => false, :null => false
    t.integer  "subscription_rate_schedule_id"
    t.datetime "returned_from_paypal_at"
    t.string   "label"
    t.string   "rep_name"
    t.string   "rep_id"
    t.string   "merchant_contact_name"
    t.string   "merchant_commission_percentage",                                 :default => "50",  :null => false
    t.string   "revenue_share_percentage",                                       :default => "50",  :null => false
    t.string   "encrypted_bank_account_number"
    t.string   "encrypted_bank_routing_number"
    t.string   "encrypted_federal_tax_id"
    t.string   "payment_type"
    t.string   "merchant_id"
    t.string   "merchant_name"
    t.string   "check_payable_to"
    t.string   "bank_name"
    t.string   "name_on_bank_account"
    t.string   "check_mailing_address_line_1"
    t.string   "check_mailing_address_line_2"
    t.string   "check_mailing_address_city"
    t.string   "check_mailing_address_state"
    t.string   "check_mailing_address_zip"
    t.datetime "deleted_at"
    t.boolean  "do_not_show_map",                                                :default => false, :null => false
    t.text     "description"
    t.boolean  "used_exclusively_for_testing",                                   :default => false
    t.string   "sales_agent_id"
    t.string   "size"
    t.boolean  "pay_all_locations",                                              :default => false, :null => false
    t.integer  "primary_store_id"
    t.string   "status"
    t.decimal  "gross_annual_turnover",           :precision => 10, :scale => 2
    t.string   "business_trading_name"
    t.boolean  "registered_with_companies_house",                                :default => false
    t.string   "primary_business_category"
    t.string   "secondary_business_category"
    t.string   "registered_company_name"
    t.string   "company_registration_number"
  end

  add_index "advertisers", ["deleted_at"], :name => "index_advertisers_on_deleted_at"
  add_index "advertisers", ["listing"], :name => "index_advertisers_on_listing"
  add_index "advertisers", ["primary_store_id"], :name => "index_advertisers_on_primary_store_id"
  add_index "advertisers", ["publisher_id", "label"], :name => "index_advertisers_on_publisher_id_and_label", :unique => true
  add_index "advertisers", ["publisher_id"], :name => "index_advertisers_on_publisher_id"

  create_table "affiliate_placements", :force => true do |t|
    t.integer  "affiliate_id"
    t.string   "affiliate_type"
    t.integer  "placeable_id"
    t.string   "placeable_type"
    t.string   "uuid"
    t.datetime "deleted_at"
  end

  add_index "affiliate_placements", ["affiliate_type", "affiliate_id"], :name => "index_affiliate_placements_on_affiliate_type_and_affiliate_id"
  add_index "affiliate_placements", ["placeable_type", "placeable_id"], :name => "index_affiliate_placements_on_placeable_type_and_placeable_id"
  add_index "affiliate_placements", ["uuid"], :name => "index_affiliate_placements_on_uuid", :unique => true

  create_table "agreements", :force => true do |t|
    t.string   "title"
    t.string   "contact_name"
    t.string   "company_name"
    t.string   "telephone_number"
    t.string   "email"
    t.boolean  "source_publisher"
    t.boolean  "distribution_publisher"
    t.boolean  "affiliate_publisher"
    t.string   "websites"
    t.string   "mobile_applications"
    t.string   "other_delivery_mechanisms"
    t.string   "serial_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "api_activity_logs", :force => true do |t|
    t.integer  "loggable_id"
    t.string   "loggable_type"
    t.string   "api_name",                                                              :null => false
    t.string   "api_activity_label",                                                    :null => false
    t.string   "request_url",                                                           :null => false
    t.string   "request_body",            :limit => 2000
    t.string   "response_body",           :limit => 2000
    t.string   "http_status_code",        :limit => 25
    t.string   "api_status_code",         :limit => 25
    t.string   "api_status_message"
    t.boolean  "request_initiated_by_us",                                               :null => false
    t.decimal  "response_time",                           :precision => 8, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "internal_status_message"
  end

  create_table "api_requests", :force => true do |t|
    t.integer  "lock_version",                              :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publisher_id"
    t.string   "type"
    t.string   "mobile_number"
    t.string   "message"
    t.string   "consumer_phone_number"
    t.string   "merchant_phone_number"
    t.string   "email_subject"
    t.string   "destination_email_address"
    t.string   "text_plain_content",        :limit => 8192
    t.string   "text_html_content",         :limit => 8192
    t.date     "dates_begin"
    t.date     "dates_end"
    t.string   "report_group"
    t.integer  "offer_id"
    t.integer  "txt_offer_id"
  end

  add_index "api_requests", ["offer_id"], :name => "index_api_requests_on_offer_id"
  add_index "api_requests", ["publisher_id", "type"], :name => "index_api_requests_on_publisher_id_and_type"
  add_index "api_requests", ["txt_offer_id"], :name => "index_api_requests_on_txt_offer_id"

  create_table "bar_codes", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bar_codeable_id"
    t.string   "bar_codeable_type"
    t.string   "code",                                 :null => false
    t.boolean  "assigned",          :default => false, :null => false
    t.integer  "position"
  end

  add_index "bar_codes", ["bar_codeable_id"], :name => "index_bar_codes_on_bar_codeable_id"
  add_index "bar_codes", ["bar_codeable_type", "bar_codeable_id", "assigned"], :name => "type_id_assigned"
  add_index "bar_codes", ["bar_codeable_type", "bar_codeable_id", "code"], :name => "index_bar_codes_on_bar_codeable_and_code"

  create_table "braintree_redirect_results", :force => true do |t|
    t.integer  "daily_deal_purchase_id"
    t.boolean  "error",                                                        :null => false
    t.string   "error_message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "daily_deal_order_id"
    t.string   "type",                   :default => "BraintreeGatewayResult"
  end

  add_index "braintree_redirect_results", ["created_at"], :name => "index_braintree_redirect_results_on_created_at"
  add_index "braintree_redirect_results", ["daily_deal_order_id"], :name => "index_braintree_redirect_results_on_daily_deal_order_id"
  add_index "braintree_redirect_results", ["daily_deal_purchase_id"], :name => "index_braintree_redirect_results_on_daily_deal_purchase_id"

  create_table "call_detail_records", :force => true do |t|
    t.string   "sid",                                :null => false
    t.datetime "date_time",                          :null => false
    t.string   "viewer_phone_number",                :null => false
    t.string   "center_phone_number"
    t.float    "intelligent_minutes"
    t.float    "talk_minutes"
    t.float    "enhanced_minutes"
    t.integer  "lock_version",        :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "voice_message_id"
  end

  add_index "call_detail_records", ["date_time"], :name => "index_call_detail_records_on_date_time"
  add_index "call_detail_records", ["sid"], :name => "index_call_detail_records_on_sid", :unique => true
  add_index "call_detail_records", ["voice_message_id"], :name => "index_call_detail_records_on_voice_message_id"

  create_table "categories", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "label"
  end

  add_index "categories", ["label"], :name => "index_categories_on_label"
  add_index "categories", ["parent_id", "name"], :name => "index_categories_on_parent_id_and_name", :unique => true
  add_index "categories", ["parent_id"], :name => "index_categories_on_parent_id"

  create_table "categories_offers", :id => false, :force => true do |t|
    t.integer "category_id", :null => false
    t.integer "offer_id",    :null => false
  end

  add_index "categories_offers", ["category_id", "offer_id"], :name => "index_categories_offers_on_category_id_and_offer_id", :unique => true
  add_index "categories_offers", ["category_id"], :name => "index_categories_offers_on_category_id"
  add_index "categories_offers", ["offer_id"], :name => "index_categories_offers_on_offer_id"

  create_table "categories_publishing_groups", :id => false, :force => true do |t|
    t.integer  "category_id"
    t.integer  "publishing_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "categories_publishing_groups", ["category_id"], :name => "index_categories_publishing_groups_on_category_id"
  add_index "categories_publishing_groups", ["publishing_group_id"], :name => "index_categories_publishing_groups_on_publishing_group_id"

  create_table "categories_subscribers", :id => false, :force => true do |t|
    t.integer  "category_id",   :null => false
    t.integer  "subscriber_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "categories_subscribers", ["category_id"], :name => "index_categories_subscribers_on_category_id"
  add_index "categories_subscribers", ["subscriber_id"], :name => "index_categories_subscribers_on_subscriber_id"

  create_table "click_counts", :force => true do |t|
    t.integer  "clickable_id",                   :null => false
    t.integer  "count",          :default => 0,  :null => false
    t.integer  "lock_version",   :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mode",           :default => "", :null => false
    t.integer  "publisher_id",                   :null => false
    t.string   "clickable_type",                 :null => false
  end

  add_index "click_counts", ["clickable_type", "clickable_id", "created_at", "mode"], :name => "clicks_on_clickable_created_at_mode"
  add_index "click_counts", ["clickable_type", "clickable_id", "publisher_id", "created_at", "mode"], :name => "clicks_on_clickable_publisher_created_at_mode", :unique => true
  add_index "click_counts", ["publisher_id", "created_at"], :name => "index_click_counts_on_publisher_id_and_created_at"

  create_table "consumer_deal_relevancy_scores", :force => true do |t|
    t.integer  "consumer_id"
    t.integer  "daily_deal_id"
    t.integer  "relevancy_score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "consumer_deal_relevancy_scores", ["consumer_id"], :name => "index_consumer_deal_relevancy_scores_on_consumer_id"

  create_table "consumer_referral_urls", :force => true do |t|
    t.integer  "consumer_id"
    t.integer  "publisher_id"
    t.string   "bit_ly_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "consumer_referral_urls", ["consumer_id"], :name => "index_consumer_referral_urls_on_consumer_id"
  add_index "consumer_referral_urls", ["publisher_id"], :name => "index_consumer_referral_urls_on_publisher_id"

  create_table "consumers_daily_deal_categories", :id => false, :force => true do |t|
    t.integer "consumer_id"
    t.integer "daily_deal_category_id"
  end

  create_table "countries", :force => true do |t|
    t.string  "name"
    t.string  "code"
    t.boolean "active",              :default => true
    t.string  "postal_code_regex"
    t.string  "calling_code",        :default => ""
    t.integer "phone_number_length"
  end

  add_index "countries", ["code"], :name => "index_countries_on_code"

  create_table "countries_publishers", :id => false, :force => true do |t|
    t.integer "country_id"
    t.integer "publisher_id"
  end

  add_index "countries_publishers", ["country_id"], :name => "index_countries_publishers_on_country_id"
  add_index "countries_publishers", ["publisher_id"], :name => "index_countries_publishers_on_publisher_id"

  create_table "credit_cards", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                        :default => 0, :null => false
    t.integer  "consumer_id"
    t.string   "token"
    t.string   "card_type"
    t.string   "last_4"
    t.string   "hexdigest"
    t.string   "billing_first_name"
    t.string   "billing_last_name"
    t.string   "billing_country_code",   :limit => 2
    t.string   "billing_address_line_1"
    t.string   "billing_address_line_2"
    t.string   "billing_city"
    t.string   "billing_state"
    t.string   "billing_postal_code"
    t.date     "expiration_date"
  end

  add_index "credit_cards", ["consumer_id", "hexdigest"], :name => "index_credit_cards_on_consumer_id_and_hexdigest"

  create_table "credits", :force => true do |t|
    t.integer  "consumer_id",                                :null => false
    t.decimal  "amount",      :precision => 10, :scale => 2, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "origin_id"
    t.string   "origin_type"
    t.text     "memo"
  end

  add_index "credits", ["consumer_id"], :name => "index_credits_on_consumer_id"

  create_table "daily_deal_affiliate_redirects", :force => true do |t|
    t.integer  "daily_deal_id"
    t.integer  "consumer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "daily_deal_categories", :force => true do |t|
    t.string   "name",                :null => false
    t.integer  "publisher_id"
    t.string   "abbreviation"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publishing_group_id"
  end

  add_index "daily_deal_categories", ["publisher_id"], :name => "index_daily_deal_categories_on_publisher_id"

  create_table "daily_deal_categories_subscribers", :id => false, :force => true do |t|
    t.integer "daily_deal_category_id"
    t.integer "subscriber_id"
  end

  create_table "daily_deal_certificates", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "daily_deal_purchase_id"
    t.string   "serial_number",                                                                            :null => false
    t.datetime "redeemed_at"
    t.string   "redeemer_name",                                                                            :null => false
    t.string   "bar_code"
    t.string   "status"
    t.decimal  "actual_purchase_price",                  :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "refund_amount",                          :precision => 10, :scale => 2, :default => 0.0
    t.datetime "refunded_at"
    t.boolean  "serial_number_generated_by_third_party",                                :default => false, :null => false
    t.boolean  "marked_used_by_user",                                                   :default => false
  end

  add_index "daily_deal_certificates", ["daily_deal_purchase_id"], :name => "index_daily_deal_certificates_on_daily_deal_purchase_id"
  add_index "daily_deal_certificates", ["refunded_at"], :name => "refunded_at_index"
  add_index "daily_deal_certificates", ["serial_number"], :name => "serial_number_index"
  add_index "daily_deal_certificates", ["status", "refunded_at"], :name => ":status_refunded_at_index"
  add_index "daily_deal_certificates", ["status"], :name => "status_index"

  create_table "daily_deal_orders", :force => true do |t|
    t.integer  "consumer_id"
    t.string   "uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "payment_gateway_id"
    t.string   "analog_purchase_id"
    t.string   "payment_status",     :default => "pending", :null => false
  end

  add_index "daily_deal_orders", ["consumer_id"], :name => "index_daily_deal_orders_on_consumer_id"
  add_index "daily_deal_orders", ["payment_status"], :name => "index_daily_deal_orders_on_payment_status"

  create_table "daily_deal_payments", :force => true do |t|
    t.string   "type"
    t.integer  "daily_deal_purchase_id"
    t.string   "analog_purchase_id"
    t.string   "payment_gateway_id"
    t.string   "payment_gateway_receipt_id"
    t.string   "credit_card_last_4"
    t.decimal  "amount",                                  :precision => 10, :scale => 2
    t.string   "payer_postal_code"
    t.string   "payer_email"
    t.string   "payer_status"
    t.datetime "payment_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "billing_address_line_1"
    t.string   "billing_address_line_2"
    t.string   "billing_city"
    t.string   "billing_state"
    t.string   "name_on_card"
    t.string   "credit_card_bin"
    t.string   "billing_first_name"
    t.string   "billing_last_name"
    t.string   "billing_country_code",       :limit => 2
  end

  add_index "daily_deal_payments", ["analog_purchase_id"], :name => "index_daily_deal_payments_on_analog_purchase_id"
  add_index "daily_deal_payments", ["daily_deal_purchase_id"], :name => "index_daily_deal_payments_on_daily_deal_purchase_id"
  add_index "daily_deal_payments", ["payment_gateway_id"], :name => "index_daily_deal_payments_on_payment_gateway_id"

  create_table "daily_deal_purchase_fixups", :force => true do |t|
    t.string   "type",                                                  :null => false
    t.integer  "daily_deal_purchase_id"
    t.decimal  "new_gross_price",        :precision => 10, :scale => 2
    t.string   "refund_txn_id"
    t.integer  "refund_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "daily_deal_purchase_fixups", ["daily_deal_purchase_id"], :name => "index_daily_deal_purchase_fixups_on_daily_deal_purchase_id", :unique => true

  create_table "daily_deal_purchase_recipients", :force => true do |t|
    t.integer  "country_id"
    t.integer  "daily_deal_purchase_id"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone_number"
    t.float    "longitude"
    t.float    "latitude"
    t.string   "region"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "daily_deal_purchases", :force => true do |t|
    t.integer  "lock_version",                                                                    :default => 0,                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "daily_deal_id",                                                                                                    :null => false
    t.integer  "consumer_id"
    t.integer  "quantity",                                                                        :default => 1,                   :null => false
    t.boolean  "gift",                                                                            :default => false,               :null => false
    t.string   "payment_status",                                                                  :default => "pending",           :null => false
    t.datetime "payment_status_updated_at"
    t.string   "payment_status_updated_by_txn_id"
    t.string   "uuid",                                                                                                             :null => false
    t.string   "recipient_names",                  :limit => 1023
    t.integer  "store_id"
    t.boolean  "allow_execution",                                                                 :default => false,               :null => false
    t.integer  "discount_id"
    t.datetime "executed_at"
    t.boolean  "post_to_facebook",                                                                :default => false
    t.decimal  "credit_used",                                      :precision => 10, :scale => 2, :default => 0.0,                 :null => false
    t.string   "ip_address"
    t.datetime "sent_to_publisher_at"
    t.datetime "refunded_at"
    t.string   "refunded_by"
    t.decimal  "refund_amount",                                    :precision => 10, :scale => 2, :default => 0.0
    t.integer  "affiliate_id"
    t.string   "affiliate_type"
    t.decimal  "gross_price",                                      :precision => 10, :scale => 2
    t.decimal  "actual_purchase_price",                            :precision => 10, :scale => 2
    t.string   "visitors_referring_id"
    t.integer  "daily_deal_order_id"
    t.integer  "market_id"
    t.string   "donation_name"
    t.string   "donation_city"
    t.string   "donation_state"
    t.datetime "certificate_email_sent_at"
    t.string   "type",                                                                            :default => "DailyDealPurchase"
    t.integer  "api_user_id"
    t.string   "device"
    t.boolean  "made_via_qr_code"
    t.string   "loyalty_program_referral_code"
    t.decimal  "loyalty_refund_amount",                            :precision => 10, :scale => 2
    t.integer  "mailing_address_id"
    t.string   "fulfillment_method",                                                              :default => "email"
    t.decimal  "voucher_shipping_amount",                          :precision => 10, :scale => 2
    t.integer  "daily_deal_variation_id"
    t.text     "memo"
  end

  add_index "daily_deal_purchases", ["api_user_id"], :name => "index_daily_deal_purchases_on_api_user_id"
  add_index "daily_deal_purchases", ["certificate_email_sent_at"], :name => "index_daily_deal_purchases_on_certificate_email_sent_at"
  add_index "daily_deal_purchases", ["consumer_id"], :name => "index_daily_deal_purchases_on_consumer_id"
  add_index "daily_deal_purchases", ["created_at"], :name => "index_daily_deal_purchases_on_created_at"
  add_index "daily_deal_purchases", ["daily_deal_id"], :name => "index_daily_deal_purchases_on_daily_deal_id"
  add_index "daily_deal_purchases", ["daily_deal_order_id"], :name => "index_daily_deal_purchases_on_daily_deal_order_id"
  add_index "daily_deal_purchases", ["daily_deal_variation_id"], :name => "index_daily_deal_purchases_on_daily_deal_variation_id"
  add_index "daily_deal_purchases", ["executed_at"], :name => "index_daily_deal_purchases_on_executed_at"
  add_index "daily_deal_purchases", ["payment_status"], :name => "index_daily_deal_purchases_on_payment_status"
  add_index "daily_deal_purchases", ["store_id"], :name => "index_daily_deal_purchases_on_store_id"
  add_index "daily_deal_purchases", ["type"], :name => "index_daily_deal_purchases_on_type"
  add_index "daily_deal_purchases", ["uuid"], :name => "index_daily_deal_purchases_on_uuid"

  create_table "daily_deal_translations", :force => true do |t|
    t.integer  "daily_deal_id"
    t.string   "locale"
    t.string   "short_description"
    t.text     "description"
    t.string   "value_proposition_subhead"
    t.string   "value_proposition"
    t.text     "reviews"
    t.text     "voucher_steps"
    t.text     "highlights"
    t.text     "email_voucher_redemption_message"
    t.string   "twitter_status_text"
    t.text     "terms"
    t.string   "facebook_title_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "disclaimer"
    t.text     "redemption_page_description"
    t.string   "side_deal_value_proposition"
    t.string   "side_deal_value_proposition_subhead"
    t.string   "custom_1"
    t.string   "custom_2"
    t.string   "custom_3"
  end

  add_index "daily_deal_translations", ["daily_deal_id"], :name => "index_daily_deal_translations_on_daily_deal_id"

  create_table "daily_deal_variation_translations", :force => true do |t|
    t.integer  "daily_deal_variation_id"
    t.string   "locale"
    t.string   "value_proposition_subhead"
    t.string   "voucher_headline"
    t.text     "terms"
    t.string   "value_proposition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "daily_deal_variation_translations", ["daily_deal_variation_id"], :name => "index_7324365043580bd2841b9c5a7af0cb5f4d915ae5"

  create_table "daily_deal_variations", :force => true do |t|
    t.integer  "daily_deal_id",                                                                            :null => false
    t.decimal  "value",                                      :precision => 10, :scale => 2,                :null => false
    t.decimal  "price",                                      :precision => 10, :scale => 2,                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "quantity"
    t.integer  "min_quantity"
    t.integer  "max_quantity"
    t.datetime "sold_out_at"
    t.string   "listing"
    t.integer  "bar_code_encoding_format",                                                  :default => 7, :null => false
    t.integer  "certificates_to_generate_per_unit_quantity",                                :default => 1, :null => false
    t.string   "travelsavers_product_code"
    t.datetime "deleted_at"
    t.text     "affiliate_url"
    t.integer  "daily_deal_sequence_id",                                                                   :null => false
  end

  add_index "daily_deal_variations", ["daily_deal_id", "daily_deal_sequence_id"], :name => "daily_deal_id_sequence_id", :unique => true
  add_index "daily_deal_variations", ["daily_deal_id"], :name => "index_daily_deal_variations_on_daily_deal_id"

  create_table "daily_deals", :force => true do |t|
    t.integer  "publisher_id"
    t.integer  "advertiser_id"
    t.string   "value_proposition_TEMP"
    t.text     "description_TEMP"
    t.text     "text"
    t.decimal  "price",                                      :precision => 10, :scale => 2,                          :null => false
    t.decimal  "value",                                      :precision => 10, :scale => 2,                          :null => false
    t.text     "terms_TEMP"
    t.text     "highlights_TEMP"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "deleted_at"
    t.datetime "start_at"
    t.datetime "hide_at"
    t.date     "expires_on"
    t.integer  "quantity"
    t.string   "bit_ly_url"
    t.string   "facebook_title_text_TEMP"
    t.string   "twitter_status_text_TEMP"
    t.string   "short_description_TEMP"
    t.integer  "min_quantity",                                                              :default => 1
    t.boolean  "location_required"
    t.datetime "sold_out_at"
    t.string   "listing"
    t.decimal  "advertiser_revenue_share_percentage",        :precision => 10, :scale => 2
    t.integer  "max_quantity",                                                              :default => 0,           :null => false
    t.text     "reviews_TEMP"
    t.string   "uuid"
    t.boolean  "featured_deprecated"
    t.integer  "bar_code_encoding_format",                                                  :default => 7,           :null => false
    t.string   "value_proposition_subhead_TEMP"
    t.boolean  "upcoming",                                                                  :default => false,       :null => false
    t.boolean  "enable_daily_email_blast",                                                  :default => false,       :null => false
    t.integer  "source_id"
    t.decimal  "affiliate_revenue_share_percentage",         :precision => 10, :scale => 2
    t.integer  "analytics_category_id"
    t.boolean  "hide_serial_number_if_bar_code_is_present",                                 :default => false
    t.text     "voucher_steps_TEMP"
    t.boolean  "cobrand_deal_vouchers"
    t.boolean  "shopping_mall",                                                             :default => false,       :null => false
    t.text     "email_voucher_redemption_message_TEMP"
    t.string   "account_executive"
    t.string   "side_deal_value_proposition_TEMP"
    t.string   "side_deal_value_proposition_subhead_TEMP"
    t.integer  "publishers_category_id"
    t.decimal  "advertiser_credit_percentage",               :precision => 10, :scale => 2
    t.boolean  "available_for_syndication",                                                 :default => false
    t.boolean  "national_deal",                                                             :default => false
    t.boolean  "requires_shipping_address",                                                 :default => false,       :null => false
    t.string   "shipping_address_message"
    t.string   "custom_1_TEMP"
    t.string   "custom_2_TEMP"
    t.string   "custom_3_TEMP"
    t.text     "affiliate_url"
    t.integer  "email_voucher_offer_id"
    t.boolean  "sold_out_via_third_party"
    t.string   "voucher_headline"
    t.integer  "number_sold_display_threshold"
    t.string   "secondary_photo_file_name"
    t.string   "secondary_photo_content_type"
    t.integer  "secondary_photo_file_size"
    t.string   "type",                                                                      :default => "DailyDeal"
    t.boolean  "featured_in_category"
    t.text     "business_fine_print"
    t.boolean  "voucher_has_qr_code",                                                                                :null => false
    t.datetime "push_notifications_sent_at"
    t.boolean  "show_on_landing_page",                                                      :default => false
    t.integer  "yelp_business_id"
    t.boolean  "qr_code_active",                                                            :default => false,       :null => false
    t.boolean  "enable_loyalty_program"
    t.integer  "referrals_required_for_loyalty_credit"
    t.datetime "side_start_at"
    t.datetime "side_end_at"
    t.integer  "certificates_to_generate_per_unit_quantity",                                :default => 1,           :null => false
    t.datetime "photo_updated_at"
    t.datetime "secondary_photo_updated_at"
    t.boolean  "non_voucher_deal"
    t.string   "travelsavers_product_code"
    t.string   "sales_agent_id"
    t.integer  "source_publisher_id"
    t.integer  "source_publishing_group_id"
    t.boolean  "has_off_platform_purchase_summary",                                         :default => false
    t.string   "status"
    t.string   "source_channel"
    t.boolean  "enable_publisher_tracking",                                                 :default => true
    t.string   "campaign_code"
  end

  add_index "daily_deals", ["advertiser_id"], :name => "index_daily_deals_on_advertiser_id"
  add_index "daily_deals", ["analytics_category_id"], :name => "index_daily_deals_on_analytics_category_id"
  add_index "daily_deals", ["available_for_syndication"], :name => "index_daily_deals_on_available_for_syndication"
  add_index "daily_deals", ["deleted_at"], :name => "index_daily_deals_on_deleted_at"
  add_index "daily_deals", ["enable_loyalty_program"], :name => "index_daily_deals_on_enable_loyalty_program"
  add_index "daily_deals", ["hide_at"], :name => "index_daily_deals_on_hide_at"
  add_index "daily_deals", ["price"], :name => "index_daily_deals_on_price"
  add_index "daily_deals", ["publisher_id", "enable_loyalty_program"], :name => "index_daily_deals_on_publisher_id_and_enable_loyalty_program"
  add_index "daily_deals", ["publisher_id"], :name => "index_daily_deals_on_publisher_id"
  add_index "daily_deals", ["side_end_at"], :name => "index_daily_deals_on_side_end_at"
  add_index "daily_deals", ["side_start_at"], :name => "index_daily_deals_on_side_start_at"
  add_index "daily_deals", ["source_id"], :name => "index_daily_deals_on_source_id"
  add_index "daily_deals", ["source_publisher_id"], :name => "index_daily_deals_on_source_publisher_id"
  add_index "daily_deals", ["source_publishing_group_id"], :name => "index_daily_deals_on_source_publishing_group_id"
  add_index "daily_deals", ["start_at"], :name => "index_daily_deals_on_start_at"
  add_index "daily_deals", ["travelsavers_product_code"], :name => "index_daily_deals_on_travelsavers_product_code"
  add_index "daily_deals", ["type"], :name => "index_daily_deals_on_type"

  create_table "daily_deals_markets", :id => false, :force => true do |t|
    t.integer "daily_deal_id"
    t.integer "market_id"
  end

  add_index "daily_deals_markets", ["daily_deal_id"], :name => "index_daily_deals_markets_on_daily_deal_id"
  add_index "daily_deals_markets", ["market_id"], :name => "index_daily_deals_markets_on_market_id"

  create_table "discounts", :force => true do |t|
    t.string   "type"
    t.integer  "publisher_id",                                                             :null => false
    t.string   "uuid",                                                                     :null => false
    t.string   "code",                                                                     :null => false
    t.decimal  "amount",                 :precision => 10, :scale => 2,                    :null => false
    t.integer  "quantity"
    t.datetime "first_usable_at"
    t.datetime "last_usable_at"
    t.boolean  "usable_at_checkout",                                    :default => true,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "lock_version",                                          :default => 0,     :null => false
    t.boolean  "usable_only_once",                                      :default => false
    t.datetime "used_at"
    t.integer  "daily_deal_purchase_id"
    t.integer  "promotion_id"
  end

  add_index "discounts", ["code", "publisher_id", "first_usable_at", "last_usable_at"], :name => "code_2"
  add_index "discounts", ["code"], :name => "code"
  add_index "discounts", ["daily_deal_purchase_id"], :name => "index_discounts_on_daily_deal_purchase_id"
  add_index "discounts", ["first_usable_at"], :name => "first_usable_at"
  add_index "discounts", ["last_usable_at"], :name => "last_usable_at"
  add_index "discounts", ["promotion_id"], :name => "index_discounts_on_promotion_id"
  add_index "discounts", ["publisher_id"], :name => "publisher_id"
  add_index "discounts", ["uuid"], :name => "index_discounts_on_uuid"

  create_table "email_recipients", :force => true do |t|
    t.string   "email_address",                   :null => false
    t.string   "random_code",                     :null => false
    t.boolean  "email_allowed", :default => true, :null => false
    t.integer  "lock_version",  :default => 0,    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_recipients", ["email_address"], :name => "index_email_recipients_on_email_address", :unique => true
  add_index "email_recipients", ["random_code"], :name => "index_email_recipients_on_random_code", :unique => true

  create_table "gateway_messages", :force => true do |t|
    t.datetime "accepted_time"
    t.string   "message",                      :null => false
    t.string   "mobile_number",                :null => false
    t.string   "type",                         :null => false
    t.integer  "lock_version",  :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gift_certificates", :force => true do |t|
    t.integer  "advertiser_id",                                                               :null => false
    t.string   "message"
    t.datetime "expires_on"
    t.string   "terms"
    t.decimal  "value",                     :precision => 10, :scale => 2
    t.decimal  "price",                     :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "show_on"
    t.boolean  "deleted",                                                  :default => false
    t.boolean  "physical_gift_certificate",                                :default => false
    t.integer  "number_allocated"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.text     "description"
    t.string   "bit_ly_url"
    t.decimal  "handling_fee",              :precision => 10, :scale => 2
    t.boolean  "collect_address",                                          :default => false
  end

  add_index "gift_certificates", ["advertiser_id"], :name => "index_gift_certificates_on_advertiser_id"
  add_index "gift_certificates", ["bit_ly_url"], :name => "index_gift_certificates_on_bit_ly_url"
  add_index "gift_certificates", ["expires_on"], :name => "index_gift_certificates_on_expires_on"
  add_index "gift_certificates", ["show_on"], :name => "index_gift_certificates_on_show_on"

  create_table "https_only_hosts", :force => true do |t|
    t.string   "host",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "impression_counts", :force => true do |t|
    t.integer  "viewable_id",                  :null => false
    t.integer  "count",         :default => 0, :null => false
    t.integer  "lock_version",  :default => 0, :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at"
    t.integer  "publisher_id",                 :null => false
    t.string   "viewable_type",                :null => false
  end

  add_index "impression_counts", ["publisher_id", "created_at"], :name => "index_impression_counts_on_publisher_id_and_created_at"
  add_index "impression_counts", ["viewable_type", "viewable_id", "created_at"], :name => "impressions_on_viewable_created_at"
  add_index "impression_counts", ["viewable_type", "viewable_id", "publisher_id", "created_at"], :name => "impressions_on_viewable_publisher_created_at", :unique => true

  create_table "inbound_txts", :force => true do |t|
    t.datetime "accepted_time"
    t.datetime "received_at"
    t.string   "keyword",                            :null => false
    t.string   "subkeyword",                         :null => false
    t.string   "message",                            :null => false
    t.string   "originator_address",                 :null => false
    t.string   "network_type",       :default => ""
    t.string   "server_address",                     :null => false
    t.string   "carrier",            :default => ""
    t.integer  "lock_version",       :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "txt_offer_id"
  end

  create_table "jobs", :force => true do |t|
    t.string   "key",                 :null => false
    t.datetime "started_at",          :null => false
    t.datetime "finished_at"
    t.datetime "increment_timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "publisher_id"
    t.string   "file_name"
  end

  add_index "jobs", ["increment_timestamp"], :name => "index_jobs_on_increment_timestamp"
  add_index "jobs", ["publisher_id"], :name => "index_jobs_on_publisher_id"

  create_table "leads", :force => true do |t|
    t.string   "email"
    t.string   "mobile_number"
    t.boolean  "call_me"
    t.integer  "lock_version",     :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remote_ip",        :default => ""
    t.string   "first_name",       :default => ""
    t.string   "last_name",        :default => ""
    t.string   "state_code",       :default => ""
    t.boolean  "use_credit_card",  :default => false, :null => false
    t.string   "type"
    t.boolean  "txt_me",           :default => false
    t.integer  "offer_id",                            :null => false
    t.string   "query_parameters"
    t.boolean  "email_me",         :default => false, :null => false
    t.boolean  "print_me",         :default => false, :null => false
    t.integer  "publisher_id",                        :null => false
  end

  add_index "leads", ["created_at"], :name => "index_leads_on_created_at"
  add_index "leads", ["offer_id", "created_at"], :name => "index_leads_on_offer_id_and_created_at"
  add_index "leads", ["offer_id", "publisher_id", "created_at"], :name => "index_leads_on_offer_id_and_publisher_id_and_created_at"
  add_index "leads", ["offer_id", "remote_ip"], :name => "index_leads_on_offer_id_and_remote_ip"
  add_index "leads", ["publisher_id", "created_at"], :name => "index_leads_on_publisher_id_and_created_at"

  create_table "manageable_publishers", :force => true do |t|
    t.integer  "publisher_id", :null => false
    t.integer  "user_id",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "manageable_publishers", ["publisher_id"], :name => "index_manageable_publishers_on_publisher_id"
  add_index "manageable_publishers", ["user_id"], :name => "index_manageable_publishers_on_user_id"

  create_table "market_zip_codes", :force => true do |t|
    t.integer  "market_id",               :null => false
    t.string   "zip_code",                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state_code", :limit => 2
  end

  add_index "market_zip_codes", ["market_id", "zip_code"], :name => "index_market_zip_codes_on_market_id_and_zip_code", :unique => true
  add_index "market_zip_codes", ["state_code"], :name => "index_market_zip_codes_on_state_code"

  create_table "markets", :force => true do |t|
    t.integer  "publisher_id"
    t.string   "name",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "google_analytics_account_ids"
  end

  add_index "markets", ["publisher_id"], :name => "publisher_id_index"

  create_table "members", :force => true do |t|
    t.string   "email"
    t.integer  "lock_version", :default => 0
    t.integer  "int",          :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mobile_phones", :force => true do |t|
    t.string   "number",                            :null => false
    t.boolean  "opt_out",        :default => false
    t.integer  "lock_version",   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "intro_txt_sent", :default => false, :null => false
  end

  add_index "mobile_phones", ["number"], :name => "index_mobile_phones_on_number", :unique => true

  create_table "new_silverpop_recipients", :force => true do |t|
    t.integer  "consumer_id"
    t.string   "silverpop_seed_database_identifier"
    t.string   "silverpop_database_identifier"
    t.string   "silverpop_list_identifier"
    t.datetime "opted_out_of_silverpop_seed_database_at"
    t.datetime "recipient_added_to_silverpop_database_at"
    t.datetime "recipient_added_to_silverpop_list_at"
    t.string   "old_email"
    t.datetime "old_email_removed_at"
    t.datetime "success_at"
    t.datetime "error_at"
    t.string   "error_message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "memo"
  end

  create_table "notes", :force => true do |t|
    t.text     "text"
    t.integer  "user_id"
    t.string   "notable_type"
    t.integer  "notable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "external_url"
    t.string   "attachment_content_type"
    t.string   "attachment_file_name"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
  end

  create_table "off_platform_daily_deal_certificates", :force => true do |t|
    t.integer  "consumer_id",                                   :null => false
    t.string   "download_url"
    t.datetime "executed_at",                                   :null => false
    t.date     "expires_on"
    t.string   "line_item_name",                                :null => false
    t.string   "redeemer_names",                                :null => false
    t.integer  "quantity_excluding_refunds",                    :null => false
    t.datetime "redeemed_at"
    t.boolean  "redeemed",                   :default => false, :null => false
    t.string   "voucher_pdf_file_name"
    t.string   "voucher_pdf_content_type"
    t.integer  "voucher_pdf_file_size"
    t.datetime "voucher_pdf_updated_at"
  end

  add_index "off_platform_daily_deal_certificates", ["consumer_id"], :name => "index_off_platform_daily_deal_certificates_on_consumer_id"
  add_index "off_platform_daily_deal_certificates", ["executed_at"], :name => "index_off_platform_daily_deal_certificates_on_executed_at"

  create_table "off_platform_purchase_summaries", :force => true do |t|
    t.integer  "daily_deal_id"
    t.decimal  "flat_fee",                          :precision => 10, :scale => 2
    t.integer  "number_of_purchases"
    t.integer  "number_of_refunds"
    t.decimal  "analog_analytics_split_percentage", :precision => 10, :scale => 2
    t.string   "gross_or_net"
    t.decimal  "paid_to_analog_analytics",          :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number_purchased"
    t.integer  "number_of_purchasers"
  end

  create_table "offer_changes", :force => true do |t|
    t.integer  "offer_id",     :null => false
    t.date     "included_on",  :null => false
    t.date     "excluded_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "listing",      :null => false
    t.integer  "publisher_id", :null => false
  end

  create_table "offers", :force => true do |t|
    t.integer  "advertiser_id"
    t.integer  "lock_version",                                                           :default => 0,      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "offer_image_file_name"
    t.string   "offer_image_content_type"
    t.integer  "offer_image_file_size"
    t.string   "message"
    t.string   "phone_number"
    t.string   "website"
    t.string   "email"
    t.string   "terms",                    :limit => 350
    t.string   "coupon_logo_file_name"
    t.string   "coupon_logo_content_type"
    t.string   "coupon_logo_file_size"
    t.string   "txt_message"
    t.string   "value_proposition"
    t.string   "value_proposition_detail"
    t.string   "coupon_background",                                                      :default => "blue", :null => false
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.integer  "offer_image_width"
    t.integer  "offer_image_height"
    t.date     "expires_on"
    t.string   "map_url"
    t.string   "bit_ly_url"
    t.date     "show_on"
    t.string   "coupon_code"
    t.string   "label"
    t.string   "featured",                                                               :default => "none", :null => false
    t.boolean  "advertiser_active",                                                      :default => true,   :null => false
    t.boolean  "showable",                                                               :default => true,   :null => false
    t.datetime "deleted_at"
    t.decimal  "popularity",                              :precision => 10, :scale => 2, :default => 0.0
    t.string   "listing"
    t.string   "headline"
    t.string   "account_executive"
    t.datetime "photo_updated_at"
    t.datetime "offer_image_updated_at"
  end

  add_index "offers", ["advertiser_id"], :name => "index_offers_on_campaign_id"
  add_index "offers", ["bit_ly_url"], :name => "index_offers_on_bit_ly_url", :unique => true
  add_index "offers", ["deleted_at"], :name => "index_offers_on_deleted_at"
  add_index "offers", ["featured"], :name => "index_offers_on_featured"

  create_table "paypal_notifications", :force => true do |t|
    t.integer  "purchased_gift_certificate_id"
    t.text     "params"
    t.string   "payment_status"
    t.datetime "verified_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "paypal_subscription_notifications", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",                                           :default => 0, :null => false
    t.string   "item_type"
    t.string   "item_id"
    t.string   "paypal_txn_type"
    t.string   "paypal_invoice"
    t.datetime "paypal_subscr_date"
    t.datetime "paypal_subscr_effective"
    t.decimal  "paypal_mc_amount3",       :precision => 10, :scale => 2
    t.string   "paypal_mc_currency"
    t.string   "paypal_period3"
    t.boolean  "paypal_recurring"
    t.integer  "paypal_recur_times"
    t.boolean  "paypal_reattempt"
    t.string   "paypal_subscr_id"
    t.string   "paypal_first_name"
    t.string   "paypal_last_name"
    t.string   "paypal_payer_email"
  end

  create_table "placements", :force => true do |t|
    t.integer  "publisher_id", :null => false
    t.integer  "offer_id",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "placements", ["offer_id"], :name => "index_placements_on_offer_id"
  add_index "placements", ["publisher_id"], :name => "index_placements_on_publisher_id"

  create_table "platform_revenue_sharing_agreements", :force => true do |t|
    t.integer  "agreement_id"
    t.string   "agreement_type"
    t.date     "effective_date"
    t.decimal  "platform_fee_gross_percentage",              :precision => 10, :scale => 2
    t.decimal  "platform_fee_net_percentage",                :precision => 10, :scale => 2
    t.string   "credit_card_fee_source"
    t.decimal  "credit_card_fee_fixed_amount",               :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_fixed_percentage",           :precision => 10, :scale => 2
    t.boolean  "credit_card_fee_net_pro_rata",                                              :default => false, :null => false
    t.decimal  "credit_card_fee_net_publisher_percentage",   :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_net_merchant_percentage",    :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_net_aa_percentage",          :precision => 10, :scale => 2
    t.boolean  "credit_card_fee_gross_pro_rata",                                            :default => false, :null => false
    t.decimal  "credit_card_fee_gross_publisher_percentage", :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_gross_merchant_percentage",  :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_gross_aa_percentage",        :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "platform_flat_fee",                          :precision => 10, :scale => 2
  end

  add_index "platform_revenue_sharing_agreements", ["agreement_id", "agreement_type"], :name => "index_platform_revenue_sharing_agreements_on_agreement"

  create_table "promotions", :force => true do |t|
    t.integer  "publishing_group_id",                                :null => false
    t.datetime "start_at",                                           :null => false
    t.datetime "end_at",                                             :null => false
    t.text     "details"
    t.decimal  "amount",              :precision => 10, :scale => 2, :null => false
    t.datetime "codes_expire_at",                                    :null => false
    t.string   "code_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "publisher_daily_deal_purchase_totals", :force => true do |t|
    t.string  "publisher_label", :null => false
    t.integer "total",           :null => false
    t.date    "date",            :null => false
  end

  add_index "publisher_daily_deal_purchase_totals", ["date"], :name => "index_publisher_daily_deal_purchase_totals_on_date"

  create_table "publisher_membership_codes", :force => true do |t|
    t.integer  "publisher_id"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "master",       :default => false
  end

  create_table "publisher_translations", :force => true do |t|
    t.integer  "publisher_id"
    t.string   "locale"
    t.text     "daily_deal_email_signature"
    t.string   "brand_txt_header"
    t.text     "account_sign_up_message"
    t.string   "daily_deal_brand_name"
    t.string   "brand_name"
    t.text     "how_it_works"
    t.string   "daily_deal_twitter_message_prefix"
    t.string   "brand_headline"
    t.text     "daily_deal_universal_terms"
    t.string   "brand_twitter_prefix"
    t.text     "gift_certificate_disclaimer"
    t.string   "daily_deal_sharing_message_prefix"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "publisher_translations", ["publisher_id"], :name => "index_publisher_translations_on_publisher_id"

  create_table "publisher_zip_codes", :force => true do |t|
    t.integer  "publisher_id", :null => false
    t.string   "zip_code",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "publisher_zip_codes", ["publisher_id", "zip_code"], :name => "index_publisher_zip_codes_on_publisher_id_and_zip_code", :unique => true

  create_table "publishers", :force => true do |t|
    t.string   "name"
    t.integer  "lock_version",                                                                                           :default => 0
    t.integer  "int",                                                                                                    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password"
    t.string   "label"
    t.string   "theme",                                                                                                  :default => "simple"
    t.boolean  "link_to_email",                                                                                          :default => true,                         :null => false
    t.boolean  "link_to_map",                                                                                            :default => true,                         :null => false
    t.boolean  "link_to_website",                                                                                        :default => true,                         :null => false
    t.boolean  "random_coupon_order",                                                                                    :default => false,                        :null => false
    t.string   "coupon_page_url"
    t.boolean  "subcategories",                                                                                          :default => false,                        :null => false
    t.integer  "publishing_group_id"
    t.string   "approval_email_address"
    t.boolean  "approval_solicited",                                                                                     :default => false,                        :null => false
    t.boolean  "do_strict_validation",                                                                                   :default => true,                         :null => false
    t.integer  "active_coupon_limit"
    t.boolean  "search_box",                                                                                             :default => true
    t.integer  "default_offer_search_distance"
    t.boolean  "self_serve",                                                                                             :default => false,                        :null => false
    t.boolean  "advertiser_has_listing",                                                                                 :default => false,                        :null => false
    t.string   "brand_name_TEMP"
    t.string   "brand_txt_header_TEMP"
    t.string   "brand_headline_TEMP"
    t.boolean  "can_create_advertisers",                                                                                 :default => true,                         :null => false
    t.string   "excluded_clipping_modes"
    t.string   "txt_keyword_prefix",                                        :limit => 32
    t.integer  "txt_keyword_number",                                                                                     :default => 0,                            :null => false
    t.boolean  "coupons_home_link",                                                                                      :default => true,                         :null => false
    t.boolean  "show_twitter_button",                                                                                    :default => false,                        :null => false
    t.boolean  "show_facebook_button",                                                                                   :default => false,                        :null => false
    t.boolean  "show_call_button",                                                                                       :default => false,                        :null => false
    t.string   "coupon_border_type",                                                                                     :default => "solid"
    t.boolean  "show_phone_number",                                                                                      :default => false
    t.text     "subscriber_recipients"
    t.boolean  "show_bottom_pagination",                                                                                 :default => false
    t.boolean  "send_intro_txt",                                                                                         :default => false,                        :null => false
    t.string   "coupon_code_prefix"
    t.boolean  "generate_coupon_code",                                                                                   :default => false
    t.string   "support_email_address"
    t.boolean  "show_small_icons",                                                                                       :default => false,                        :null => false
    t.boolean  "printed_coupon_map",                                                                                     :default => false,                        :null => false
    t.string   "bit_ly_login"
    t.string   "bit_ly_api_key"
    t.boolean  "allow_gift_certificates",                                                                                :default => false
    t.string   "categories_recipients"
    t.boolean  "auto_insert_expiration_date",                                                                            :default => true
    t.integer  "active_txt_coupon_limit"
    t.string   "production_subdomain"
    t.string   "brand_twitter_prefix_TEMP"
    t.string   "advanced_search_link_target",                                                                            :default => "_top"
    t.string   "paypal_checkout_header_image_file_name"
    t.integer  "paypal_checkout_header_image_file_size"
    t.string   "paypal_checkout_header_image_content_type"
    t.datetime "paypal_checkout_header_image_updated_at"
    t.boolean  "show_gift_certificate_button",                                                                           :default => false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone_number"
    t.boolean  "place_offers_with_group",                                                                                :default => false,                        :null => false
    t.boolean  "place_all_group_offers",                                                                                 :default => false
    t.boolean  "enable_paypal_buy_now",                                                                                  :default => false,                        :null => false
    t.boolean  "enable_featured_gift_certificate",                                                                       :default => false
    t.string   "production_host"
    t.boolean  "allow_daily_deals",                                                                                      :default => false
    t.string   "support_url"
    t.text     "gift_certificate_disclaimer_TEMP"
    t.string   "sales_email_address"
    t.boolean  "enable_search_by_publishing_group",                                                                      :default => false
    t.string   "default_offer_search_postal_code"
    t.boolean  "show_zip_code_search_box",                                                                               :default => false
    t.boolean  "require_daily_deal_short_description",                                                                   :default => false,                        :null => false
    t.integer  "analytics_provider_id"
    t.string   "analytics_site_id"
    t.integer  "page_preference",                                                                                        :default => 4
    t.string   "google_map_api_key"
    t.float    "google_map_longitude"
    t.float    "google_map_latitude"
    t.integer  "google_map_zoom_level"
    t.boolean  "use_production_host_for_facebook_shares",                                                                :default => false
    t.boolean  "launched",                                                                                               :default => false
    t.boolean  "notify_via_email_on_coupon_changes",                                                                     :default => false
    t.string   "time_zone",                                                                                              :default => "Pacific Time (US & Canada)"
    t.string   "payment_method",                                                                                         :default => "paypal"
    t.string   "login_url"
    t.boolean  "allow_discount_codes",                                                                                   :default => false,                        :null => false
    t.string   "production_daily_deal_host"
    t.boolean  "advertiser_self_serve",                                                                                  :default => false,                        :null => false
    t.boolean  "show_special_deal",                                                                                      :default => false
    t.string   "daily_deal_sharing_message_prefix_TEMP"
    t.string   "daily_deal_logo_file_name"
    t.string   "daily_deal_logo_content_type"
    t.integer  "daily_deal_logo_file_size"
    t.datetime "daily_deal_logo_updated_at"
    t.text     "daily_deal_universal_terms_TEMP"
    t.text     "how_it_works_TEMP"
    t.string   "daily_deal_twitter_message_prefix_TEMP"
    t.string   "daily_deal_brand_name_TEMP"
    t.boolean  "require_billing_address",                                                                                :default => false
    t.text     "daily_deal_email_signature_TEMP"
    t.string   "listing"
    t.boolean  "offer_has_listing",                                                                                      :default => false,                        :null => false
    t.decimal  "daily_deal_referral_credit_amount",                                       :precision => 10, :scale => 2, :default => 10.0,                         :null => false
    t.string   "daily_deal_referral_message_head"
    t.string   "daily_deal_referral_message_body"
    t.integer  "unique_subscribers_count",                                                                               :default => 0,                            :null => false
    t.integer  "past_daily_deals_number_sold",                                                                           :default => 10
    t.boolean  "enable_daily_deal_referral",                                                                             :default => false,                        :null => false
    t.string   "facebook_page_url"
    t.string   "facebook_app_id"
    t.string   "facebook_api_key"
    t.string   "facebook_app_secret"
    t.text     "account_sign_up_message_TEMP"
    t.string   "daily_deal_referral_message"
    t.integer  "email_blast_hour",                                                                                       :default => 5,                            :null => false
    t.integer  "email_blast_minute",                                                                                     :default => 0,                            :null => false
    t.string   "currency_code",                                             :limit => 3,                                 :default => "USD"
    t.string   "market_name"
    t.boolean  "require_daily_deal_category",                                                                            :default => false,                        :null => false
    t.boolean  "boolean",                                                                                                :default => false,                        :null => false
    t.string   "coupons_homepage",                                                                                       :default => "grid",                       :null => false
    t.integer  "country_id"
    t.string   "region"
    t.string   "support_phone_number"
    t.text     "google_analytics_account_ids"
    t.boolean  "allow_admins_to_edit_advertiser_revenue_share_percentage",                                               :default => true,                         :null => false
    t.boolean  "ignore_daily_deal_short_description_size",                                                               :default => false,                        :null => false
    t.boolean  "enable_side_deal_value_proposition_features",                                                            :default => false,                        :null => false
    t.boolean  "enable_offer_headline",                                                                                  :default => false,                        :null => false
    t.boolean  "enable_publisher_daily_deal_categories",                                                                 :default => false,                        :null => false
    t.boolean  "enable_sweepstakes",                                                                                     :default => false
    t.boolean  "enable_unlimited_referral_time",                                                                         :default => false,                        :null => false
    t.boolean  "require_advertiser_revenue_share_percentage",                                                            :default => false,                        :null => false
    t.boolean  "exclude_from_market_selection",                                                                          :default => false,                        :null => false
    t.boolean  "shopping_cart",                                                                                          :default => false,                        :null => false
    t.boolean  "enable_daily_deal_voucher_headline",                                                                     :default => false
    t.boolean  "allow_seven_digit_advertiser_phone_numbers",                                                             :default => false,                        :null => false
    t.string   "merchant_account_id"
    t.boolean  "enable_affiliate_url_popup",                                                                             :default => false
    t.boolean  "enable_affiliate_url",                                                                                   :default => false
    t.string   "parent_theme"
    t.integer  "number_sold_display_threshold_default",                                                                  :default => 5000
    t.string   "sub_theme"
    t.boolean  "offers_available_for_syndication"
    t.string   "consumer_authentication_strategy"
    t.boolean  "allow_secondary_daily_deal_photo"
    t.boolean  "notify_third_parties_of_consumer_creation",                                                              :default => false
    t.string   "consumer_after_create_strategy"
    t.integer  "default_daily_deal_zip_radius",                                                                          :default => 0,                            :null => false
    t.string   "custom_consumer_password_reset_url"
    t.boolean  "allow_registration_during_purchase",                                                                     :default => true,                         :null => false
    t.boolean  "in_syndication_network",                                                                                 :default => false
    t.string   "suggested_daily_deal_email_address"
    t.string   "yelp_consumer_key"
    t.string   "yelp_consumer_secret"
    t.string   "yelp_token"
    t.string   "yelp_token_secret"
    t.string   "qr_code_host"
    t.string   "apple_app_store_url"
    t.boolean  "allow_offers"
    t.boolean  "allow_all_deals_page"
    t.boolean  "allow_daily_deal_disclaimer"
    t.string   "silverpop_list_identifier"
    t.string   "silverpop_template_identifier"
    t.boolean  "enable_daily_deal_yelp_reviews"
    t.boolean  "allow_consumer_show_action",                                                                             :default => false
    t.boolean  "uses_daily_deal_subscribers_presignup",                                                                  :default => false,                        :null => false
    t.boolean  "shopping_mall",                                                                                          :default => false
    t.boolean  "enable_loyalty_program_for_new_deals"
    t.integer  "referrals_required_for_loyalty_credit_for_new_deals"
    t.boolean  "allow_voucher_shipping",                                                                                 :default => false
    t.boolean  "can_preview_daily_deal_certificates",                                                                    :default => false,                        :null => false
    t.boolean  "enable_market_menu"
    t.boolean  "enable_fraud_detection",                                                                                 :default => false,                        :null => false
    t.string   "silverpop_seed_database_identifier"
    t.string   "email_blast_day_of_week"
    t.boolean  "send_weekly_email_blast_to_seed_list",                                                                   :default => false
    t.boolean  "send_weekly_email_blast_to_contact_list",                                                                :default => false
    t.string   "silverpop_seed_template_identifier"
    t.boolean  "allow_past_deals_page",                                                                                  :default => false
    t.boolean  "daily_deals_available_for_syndication_by_default_override"
    t.integer  "weekly_email_blast_scheduling_window_start_in_hours",                                                    :default => 4
    t.string   "encrypted_federal_tax_id"
    t.datetime "started_at"
    t.datetime "launched_at"
    t.datetime "terminated_at"
    t.boolean  "send_litle_campaign",                                                                                    :default => true
    t.boolean  "used_exclusively_for_testing",                                                                           :default => false
    t.boolean  "enable_daily_deal_variations",                                                                           :default => false
    t.boolean  "in_travelsavers_syndication_network"
    t.boolean  "enable_sales_agent_id_for_advertisers",                                                                  :default => false
    t.string   "custom_cancel_url"
    t.boolean  "main_publisher",                                                                                         :default => false
    t.string   "enabled_locales",                                                                                        :default => "--- []\n\n"
    t.string   "custom_paypal_cancel_return_url"
    t.boolean  "aa_to_pay_merchants"
    t.boolean  "enable_daily_deal_statuses",                                                                             :default => false
    t.boolean  "enable_advertiser_statuses",                                                                             :default => false
    t.boolean  "send_daily_deal_notification",                                                                           :default => false
    t.string   "notification_email_address"
  end

  add_index "publishers", ["in_syndication_network"], :name => "index_publishers_on_in_syndication_network"
  add_index "publishers", ["label"], :name => "index_publishers_on_label", :unique => true
  add_index "publishers", ["name"], :name => "index_publishers_on_name", :unique => true
  add_index "publishers", ["publishing_group_id"], :name => "index_publishers_on_publishing_group_id"

  create_table "publishers_publishers_excluded_from_distribution", :id => false, :force => true do |t|
    t.integer "publisher_id"
    t.integer "publisher_excluded_from_distribution_id"
  end

  create_table "publishing_groups", :force => true do |t|
    t.string   "name"
    t.integer  "lock_version",                                                                     :default => 0,            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "coupon_codes",                                                                     :default => true,         :null => false
    t.boolean  "self_serve",                                                                       :default => false,        :null => false
    t.string   "label"
    t.text     "how_it_works"
    t.boolean  "advertiser_financial_detail",                                                      :default => false,        :null => false
    t.string   "facebook_page_url"
    t.string   "facebook_app_id"
    t.string   "facebook_api_key"
    t.string   "facebook_app_secret"
    t.text     "consumer_recipients"
    t.text     "google_analytics_account_ids"
    t.boolean  "require_federal_tax_id",                                                           :default => false,        :null => false
    t.boolean  "stick_consumer_to_publisher_based_on_zip_code",                                    :default => false
    t.boolean  "require_login_for_active_daily_deal_feed",                                         :default => true
    t.string   "merchant_account_id"
    t.string   "parent_theme"
    t.integer  "number_sold_display_threshold_default",                                            :default => 5000
    t.boolean  "redirect_to_deal_of_the_day_on_market_lookup",                                     :default => false
    t.boolean  "allows_donations",                                                                 :default => false
    t.boolean  "notify_third_parties_of_consumer_creation",                                        :default => false
    t.string   "consumer_authentication_strategy"
    t.string   "consumer_after_create_strategy"
    t.boolean  "require_publisher_membership_codes"
    t.string   "custom_consumer_password_reset_url"
    t.boolean  "restrict_syndication_to_publishing_group",                                         :default => false,        :null => false
    t.boolean  "allow_single_sign_on",                                                             :default => false
    t.boolean  "unique_email_across_publishing_group",                                             :default => false
    t.boolean  "allow_publisher_switch_on_login",                                                  :default => false
    t.string   "yelp_consumer_key"
    t.string   "yelp_consumer_secret"
    t.string   "yelp_token"
    t.string   "yelp_token_secret"
    t.string   "qr_code_host"
    t.string   "apple_app_store_url"
    t.boolean  "show_daily_deals_on_landing_page"
    t.boolean  "send_litle_campaign",                                                              :default => true,         :null => false
    t.string   "silverpop_api_host"
    t.string   "silverpop_api_username"
    t.string   "silverpop_api_password"
    t.boolean  "allow_consumer_show_action",                                                       :default => false
    t.boolean  "voucher_has_qr_code_default",                                                      :default => false,        :null => false
    t.integer  "max_quantity_default",                                                             :default => 10,           :null => false
    t.text     "terms_default",                                                                                              :null => false
    t.string   "silverpop_database_identifier"
    t.string   "consumer_after_update_strategy"
    t.string   "silverpop_template_identifier"
    t.string   "silverpop_seed_template_identifier"
    t.string   "silverpop_account_time_zone"
    t.boolean  "uses_paychex",                                                                     :default => false,        :null => false
    t.decimal  "paychex_initial_payment_percentage",                 :precision => 5, :scale => 2
    t.integer  "paychex_num_days_after_which_full_payment_released"
    t.boolean  "daily_deals_available_for_syndication_by_default",                                 :default => false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.boolean  "allow_non_voucher_deals"
    t.boolean  "use_vault",                                                                        :default => false
    t.boolean  "enable_daily_deal_variations"
    t.boolean  "enable_redirect_to_last_seen_deal_on_login",                                       :default => false
    t.boolean  "enable_redirect_to_local_static_pages",                                            :default => false
    t.string   "enabled_locales",                                                                  :default => "--- []\n\n"
    t.boolean  "enable_force_valid_consumers",                                                     :default => false
    t.boolean  "enable_redirect_to_users_publisher",                                               :default => false
    t.boolean  "aa_to_pay_merchants"
  end

  add_index "publishing_groups", ["label"], :name => "index_publishing_groups_on_label"

  create_table "purchased_daily_deals", :force => true do |t|
    t.integer  "daily_deal_id"
    t.integer  "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "purchased_gift_certificates", :force => true do |t|
    t.integer  "gift_certificate_id",                                                                :null => false
    t.string   "paypal_address_name"
    t.string   "serial_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "paypal_payment_date"
    t.string   "paypal_address_street"
    t.string   "paypal_address_city"
    t.string   "paypal_address_state"
    t.string   "paypal_address_zip"
    t.string   "paypal_payer_email"
    t.string   "paypal_invoice"
    t.string   "paypal_first_name"
    t.string   "paypal_last_name"
    t.string   "paypal_address_status"
    t.string   "paypal_contact_phone"
    t.string   "paypal_payer_status"
    t.string   "paypal_txn_id"
    t.string   "paypal_receipt_id"
    t.string   "payment_status"
    t.datetime "payment_status_updated_at"
    t.string   "payment_status_updated_by_txn_id"
    t.decimal  "paypal_payment_gross",             :precision => 10, :scale => 2
    t.boolean  "redeemed",                                                        :default => false, :null => false
  end

  add_index "purchased_gift_certificates", ["gift_certificate_id"], :name => "index_purchased_gift_certificates_on_gift_certificate_id"
  add_index "purchased_gift_certificates", ["paypal_receipt_id"], :name => "index_purchased_gift_certificates_on_paypal_receipt_id"
  add_index "purchased_gift_certificates", ["paypal_txn_id"], :name => "index_purchased_gift_certificates_on_paypal_txn_id"
  add_index "purchased_gift_certificates", ["serial_number"], :name => "index_purchased_gift_certificates_on_serial_number", :unique => true

  create_table "push_notification_devices", :force => true do |t|
    t.integer  "publisher_id"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "push_notification_devices", ["publisher_id", "token"], :name => "index_push_notification_devices_on_publisher_id_and_token", :unique => true

  create_table "recipients", :force => true do |t|
    t.integer  "country_id"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone_number"
    t.float    "longitude"
    t.float    "latitude"
    t.string   "region"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "addressable_type"
    t.string   "addressable_id"
  end

  create_table "scheduled_mailings", :force => true do |t|
    t.integer  "publisher_id"
    t.date     "mailing_date"
    t.string   "mailing_name"
    t.string   "remote_mailing_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "success_at"
    t.datetime "error_at"
    t.string   "error_message"
  end

  create_table "silverpop_contact_audit_run_errors", :force => true do |t|
    t.integer  "silverpop_contact_audit_run_id"
    t.datetime "error_at"
    t.text     "error_details"
  end

  create_table "silverpop_contact_audit_runs", :force => true do |t|
    t.integer  "publisher_id"
    t.integer  "number_of_contacts_audited"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "silverpop_list_moves", :force => true do |t|
    t.integer  "consumer_id"
    t.integer  "old_publisher_id"
    t.integer  "new_publisher_id"
    t.string   "old_list_identifier"
    t.string   "new_list_identifier"
    t.datetime "removed_from_old_list_at"
    t.datetime "added_to_new_list_at"
    t.datetime "success_at"
    t.datetime "error_at"
    t.datetime "error_message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "memo"
  end

  create_table "stores", :force => true do |t|
    t.integer  "advertiser_id",                      :null => false
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone_number"
    t.integer  "lock_version",        :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "longitude"
    t.float    "latitude"
    t.integer  "position",            :default => 1, :null => false
    t.integer  "country_id"
    t.string   "region"
    t.string   "listing"
    t.datetime "terminated_at"
    t.string   "uuid"
    t.integer  "primary_store_of_id"
  end

  add_index "stores", ["advertiser_id"], :name => "index_stores_on_advertiser_id"
  add_index "stores", ["listing"], :name => "listing_index"
  add_index "stores", ["primary_store_of_id"], :name => "index_stores_on_primary_store_of_id"
  add_index "stores", ["uuid"], :name => "index_stores_on_uuid"
  add_index "stores", ["zip"], :name => "index_stores_on_zip"

  create_table "subscriber_referrer_codes", :force => true do |t|
    t.string   "code",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscribers", :force => true do |t|
    t.string   "email"
    t.string   "mobile_number"
    t.integer  "publisher_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "other_options"
    t.string   "zip_code"
    t.string   "name"
    t.integer  "subscriber_referrer_code_id"
    t.integer  "age"
    t.string   "gender"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "birth_year"
    t.string   "region"
    t.string   "device"
    t.string   "user_agent"
    t.string   "city"
    t.string   "state"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.integer  "publishing_group_id"
    t.string   "preferred_locale"
    t.string   "bonus_signup_code"
  end

  add_index "subscribers", ["email"], :name => "index_subscribers_on_email"
  add_index "subscribers", ["publisher_id", "email"], :name => "publisher_id_email_index"
  add_index "subscribers", ["publisher_id"], :name => "index_subscribers_on_publisher_id"
  add_index "subscribers", ["publishing_group_id"], :name => "index_subscribers_on_publishing_group_id"

  create_table "subscribers_subscription_locations", :id => false, :force => true do |t|
    t.integer "subscriber_id"
    t.integer "subscription_location_id"
  end

  create_table "subscription_locations", :force => true do |t|
    t.string  "name"
    t.integer "publisher_id"
  end

  create_table "subscription_rate_schedules", :force => true do |t|
    t.integer  "lock_version",    :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "item_owner_id"
    t.string   "item_owner_type"
    t.string   "name",                           :null => false
    t.string   "uuid",                           :null => false
  end

  create_table "subscription_rates", :force => true do |t|
    t.integer  "lock_version",                                                 :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subscription_rate_schedule_id"
    t.string   "name",                                                                            :null => false
    t.string   "description_1"
    t.string   "description_2"
    t.string   "description_3"
    t.decimal  "regular_price",                 :precision => 10, :scale => 2,                    :null => false
    t.integer  "regular_period",                                                                  :null => false
    t.string   "regular_time_unit",                                                               :null => false
    t.boolean  "recurs",                                                       :default => false, :null => false
    t.integer  "recurring_count"
  end

  create_table "suggested_daily_deals", :force => true do |t|
    t.integer  "publisher_id"
    t.integer  "consumer_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "suspected_frauds", :force => true do |t|
    t.float    "score"
    t.integer  "suspect_daily_deal_purchase_id"
    t.integer  "matched_daily_deal_purchase_id"
    t.integer  "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "suspected_frauds", ["job_id"], :name => "index_suspected_frauds_on_job_id"
  add_index "suspected_frauds", ["matched_daily_deal_purchase_id"], :name => "index_suspected_frauds_on_matched_daily_deal_purchase_id"
  add_index "suspected_frauds", ["suspect_daily_deal_purchase_id"], :name => "index_suspected_frauds_on_suspect_daily_deal_purchase_id", :unique => true

  create_table "sweepstake_entries", :force => true do |t|
    t.integer  "sweepstake_id"
    t.integer  "consumer_id"
    t.string   "phone_number"
    t.boolean  "agree_to_terms"
    t.boolean  "is_an_adult"
    t.boolean  "winner",                     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "receive_promotional_emails"
  end

  create_table "sweepstakes", :force => true do |t|
    t.string   "value_proposition"
    t.string   "value_proposition_subhead"
    t.integer  "publisher_id"
    t.text     "description"
    t.text     "terms"
    t.string   "short_description"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.string   "logo_alternate_file_name"
    t.string   "logo_alternate_content_type"
    t.integer  "logo_alternate_file_size"
    t.datetime "start_at"
    t.datetime "hide_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "max_entries_per_period"
    t.string   "max_entries_period"
    t.boolean  "unlimited_entries",                :default => true,  :null => false
    t.boolean  "featured",                         :default => false
    t.text     "official_rules"
    t.string   "promotional_opt_in_text"
    t.boolean  "show_promotional_opt_in_checkbox", :default => false
    t.datetime "photo_updated_at"
    t.datetime "logo_updated_at"
    t.datetime "logo_alternate_updated_at"
  end

  create_table "syndication_revenue_sharing_agreements", :force => true do |t|
    t.integer  "agreement_id"
    t.string   "agreement_type"
    t.date     "effective_date"
    t.decimal  "syndication_fee_gross_percentage",             :precision => 10, :scale => 2
    t.decimal  "syndication_fee_net_percentage",               :precision => 10, :scale => 2
    t.string   "credit_card_fee_source"
    t.decimal  "credit_card_fee_fixed_amount",                 :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_fixed_percentage",             :precision => 10, :scale => 2
    t.boolean  "credit_card_fee_net_pro_rata",                                                :default => false, :null => false
    t.decimal  "credit_card_fee_net_source_percentage",        :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_net_merchant_percentage",      :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_net_distributor_percentage",   :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_net_aa_percentage",            :precision => 10, :scale => 2
    t.boolean  "credit_card_fee_gross_pro_rata",                                              :default => false, :null => false
    t.decimal  "credit_card_fee_gross_source_percentage",      :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_gross_merchant_percentage",    :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_gross_distributor_percentage", :precision => 10, :scale => 2
    t.decimal  "credit_card_fee_gross_aa_percentage",          :precision => 10, :scale => 2
    t.boolean  "approved_for_syndication"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "syndication_flat_fee",                         :precision => 10, :scale => 2
    t.boolean  "approved",                                                                    :default => false, :null => false
  end

  add_index "syndication_revenue_sharing_agreements", ["agreement_id", "agreement_type"], :name => "index_syndication_revenue_sharing_agreements_on_agreement"

  create_table "syndication_revenue_splits", :force => true do |t|
    t.integer  "daily_deal_id"
    t.string   "revenue_split_type",                                                     :null => false
    t.decimal  "merchant_net_percentage",                 :precision => 10, :scale => 2
    t.decimal  "source_net_percentage_of_remaining",      :precision => 10, :scale => 2
    t.decimal  "distributor_net_percentage_of_remaining", :precision => 10, :scale => 2
    t.decimal  "aa_net_percentage_of_remaining",          :precision => 10, :scale => 2
    t.decimal  "source_gross_percentage",                 :precision => 10, :scale => 2
    t.decimal  "merchant_gross_percentage",               :precision => 10, :scale => 2
    t.decimal  "distributor_gross_percentage",            :precision => 10, :scale => 2
    t.decimal  "aa_gross_percentage",                     :precision => 10, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "syndication_revenue_splits", ["daily_deal_id"], :name => "index_syndication_revenue_splits_on_daily_deal_id"

  create_table "third_party_deals_api_configs", :force => true do |t|
    t.string   "api_username",               :null => false
    t.string   "api_password",               :null => false
    t.integer  "publisher_id",               :null => false
    t.string   "voucher_serial_numbers_url"
    t.string   "voucher_status_request_url"
    t.string   "voucher_status_change_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "third_party_event_purchases", :force => true do |t|
    t.integer  "third_party_event_id"
    t.decimal  "price",                :precision => 10, :scale => 2, :default => 0.0, :null => false
    t.integer  "quantity",                                                             :null => false
    t.string   "product_id"
    t.string   "transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "third_party_events", :force => true do |t|
    t.integer  "visitor_id"
    t.string   "visitor_type"
    t.integer  "third_party_id"
    t.string   "third_party_type"
    t.string   "third_party_label"
    t.integer  "target_id"
    t.string   "target_type"
    t.string   "action",            :null => false
    t.string   "url"
    t.string   "referral_url"
    t.string   "session_id",        :null => false
    t.string   "ip_address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "third_party_purchases_api_configs", :force => true do |t|
    t.string   "callback_username"
    t.string   "callback_password"
    t.string   "callback_url"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "third_party_purchases_api_configs", ["user_id"], :name => "index_third_party_purchases_api_configs_on_user_id"

  create_table "travelsavers_bookings", :force => true do |t|
    t.integer  "daily_deal_purchase_id",                    :null => false
    t.text     "book_transaction_xml"
    t.string   "booking_status"
    t.string   "payment_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",           :default => 0,     :null => false
    t.string   "book_transaction_id",                       :null => false
    t.datetime "service_start_date"
    t.datetime "service_end_date"
    t.boolean  "needs_manual_review",    :default => false
  end

  add_index "travelsavers_bookings", ["booking_status"], :name => "index_travelsavers_bookings_on_booking_status"
  add_index "travelsavers_bookings", ["daily_deal_purchase_id"], :name => "index_travelsavers_bookings_on_daily_deal_purchase_id"
  add_index "travelsavers_bookings", ["payment_status"], :name => "index_travelsavers_bookings_on_payment_status"
  add_index "travelsavers_bookings", ["service_end_date"], :name => "index_tmp_new_travelsavers_bookings_on_service_end_date"
  add_index "travelsavers_bookings", ["service_start_date"], :name => "index_tmp_new_travelsavers_bookings_on_service_start_date"

  create_table "txt_offers", :force => true do |t|
    t.integer  "advertiser_id"
    t.string   "short_code",    :limit => 128,                    :null => false
    t.string   "keyword",       :limit => 128,                    :null => false
    t.string   "message"
    t.integer  "lock_version",                 :default => 0,     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "appears_on"
    t.date     "expires_on"
    t.string   "label"
    t.boolean  "deleted",                      :default => false, :null => false
  end

  add_index "txt_offers", ["advertiser_id"], :name => "index_txt_offers_on_advertiser_id"
  add_index "txt_offers", ["short_code", "keyword"], :name => "index_txt_responses_on_short_code_and_keyword"

  create_table "txts", :force => true do |t|
    t.datetime "accepted_time"
    t.string   "message"
    t.string   "mobile_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",                   :default => "created", :null => false
    t.datetime "sent_at"
    t.integer  "gateway_response_code"
    t.string   "gateway_response_message"
    t.integer  "lock_version",             :default => 0
    t.integer  "lead_id"
    t.datetime "send_at"
    t.integer  "gateway_response_id"
    t.integer  "retries",                  :default => 0,         :null => false
    t.integer  "api_request_id"
    t.integer  "source_id"
    t.string   "source_type"
  end

  add_index "txts", ["api_request_id"], :name => "index_txts_on_api_request_id"

  create_table "user_companies", :force => true do |t|
    t.integer  "user_id",      :null => false
    t.integer  "company_id",   :null => false
    t.string   "company_type", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_companies", ["company_id", "company_type"], :name => "company_id_and_type_idx"
  add_index "user_companies", ["company_id"], :name => "index_user_companies_on_company_id"
  add_index "user_companies", ["company_type"], :name => "index_user_companies_on_company_type"
  add_index "user_companies", ["user_id"], :name => "index_user_companies_on_user_id"

  create_table "user_logs", :force => true do |t|
    t.integer  "user_id"
    t.string   "action"
    t.string   "ip_address"
    t.datetime "created_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name",                                             :limit => 100,                                :default => ""
    t.string   "email",                                            :limit => 100
    t.string   "crypted_password",                                 :limit => 40
    t.string   "salt",                                             :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",                                   :limit => 40
    t.datetime "remember_token_expires_at"
    t.integer  "session_timeout",                                                                                :default => 0,      :null => false
    t.string   "login",                                                                                                              :null => false
    t.string   "label"
    t.string   "perishable_token"
    t.integer  "publisher_id"
    t.string   "type",                                                                                           :default => "User", :null => false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "activation_code"
    t.datetime "activated_at"
    t.boolean  "agree_to_terms",                                                                                 :default => false,  :null => false
    t.boolean  "need_setup",                                                                                     :default => false,  :null => false
    t.integer  "signup_discount_id"
    t.string   "zip_code"
    t.string   "mobile_number"
    t.string   "facebook_id"
    t.string   "link"
    t.integer  "timezone"
    t.string   "token"
    t.decimal  "credit_available",                                                :precision => 10, :scale => 2, :default => 0.0,    :null => false
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "billing_city"
    t.string   "state"
    t.string   "country_code"
    t.string   "referral_code"
    t.string   "referrer_code"
    t.string   "bit_ly_url"
    t.integer  "birth_year"
    t.string   "gender"
    t.string   "remote_record_id"
    t.datetime "remote_record_updated_at"
    t.string   "device"
    t.string   "user_agent"
    t.string   "affiliate_code"
    t.boolean  "allow_syndication_access",                                                                       :default => false,  :null => false
    t.string   "preferred_locale"
    t.string   "bonus_signup_code"
    t.boolean  "allow_offer_syndication_access"
    t.string   "admin_privilege",                                  :limit => 1
    t.boolean  "force_password_reset",                                                                           :default => false,  :null => false
    t.boolean  "has_accountant_privilege",                                                                       :default => false,  :null => false
    t.boolean  "has_revenue_sharing_agreement_approver_privilege",                                               :default => false,  :null => false
    t.integer  "publisher_membership_code_id"
    t.datetime "locked_at"
    t.integer  "failed_login_attempts",                                                                          :default => 0,      :null => false
    t.boolean  "can_manage_consumers",                                                                           :default => false
    t.boolean  "in_vault",                                                                                       :default => false,  :null => false
    t.datetime "credit_available_reset_at"
    t.string   "active_session_token"
    t.boolean  "has_fee_sharing_agreement_approver_privilege",                                                   :default => false
    t.string   "purchase_auth_token"
  end

  add_index "users", ["activation_code"], :name => "activation_code"
  add_index "users", ["active_session_token"], :name => "index_users_on_active_session_token"
  add_index "users", ["affiliate_code"], :name => "index_users_on_affiliate_code"
  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["login", "publisher_id"], :name => "index_users_on_login_and_publisher_id", :unique => true
  add_index "users", ["login"], :name => "login"
  add_index "users", ["name"], :name => "name"
  add_index "users", ["perishable_token"], :name => "index_users_on_perishable_token"
  add_index "users", ["publisher_id", "activation_code"], :name => "publisher_id"
  add_index "users", ["publisher_id", "facebook_id"], :name => "publisher_id_2"
  add_index "users", ["publisher_id"], :name => "index_users_on_publisher_id"
  add_index "users", ["referrer_code"], :name => "index_users_on_referrer_code", :unique => true
  add_index "users", ["type"], :name => "index_users_on_type"

  create_table "versions", :force => true do |t|
    t.integer  "versioned_id"
    t.string   "versioned_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "user_name"
    t.text     "changes"
    t.integer  "number"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "versions", ["created_at"], :name => "index_versions_on_created_at"
  add_index "versions", ["number"], :name => "index_versions_on_number"
  add_index "versions", ["tag"], :name => "index_versions_on_tag"
  add_index "versions", ["user_id", "user_type"], :name => "index_versions_on_user_id_and_user_type"
  add_index "versions", ["user_name"], :name => "index_versions_on_user_name"
  add_index "versions", ["versioned_id", "versioned_type"], :name => "index_versions_on_versioned_id_and_versioned_type"

  create_table "visitors", :force => true do |t|
    t.integer  "lock_version", :default => 0
    t.integer  "int",          :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "voice_messages", :force => true do |t|
    t.string   "mobile_number",                                   :null => false
    t.string   "voice_response_code"
    t.string   "status",                   :default => "created", :null => false
    t.datetime "sent_at"
    t.integer  "gateway_response_code"
    t.string   "gateway_response_message"
    t.integer  "lock_version",             :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "send_at"
    t.integer  "lead_id"
    t.string   "call_detail_record_sid"
    t.integer  "retries",                  :default => 0,         :null => false
    t.string   "center_phone_number"
    t.integer  "api_request_id"
  end

  add_index "voice_messages", ["api_request_id"], :name => "index_voice_messages_on_api_request_id"
  add_index "voice_messages", ["call_detail_record_sid"], :name => "index_voice_messages_on_call_detail_record_sid", :unique => true
  add_index "voice_messages", ["lead_id"], :name => "index_voice_messages_on_coupon_request_id"

  create_table "yelp_businesses", :force => true do |t|
    t.string   "yelp_id"
    t.string   "name"
    t.string   "url"
    t.string   "rating_image_url"
    t.float    "average_rating"
    t.integer  "review_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "yelp_reviews", :force => true do |t|
    t.integer  "yelp_business_id"
    t.string   "yelp_id"
    t.string   "excerpt"
    t.string   "user_name"
    t.string   "user_image_url"
    t.integer  "rating"
    t.datetime "reviewed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "zip_codes", :force => true do |t|
    t.string "zip"
    t.string "city"
    t.string "state",     :limit => 2
    t.float  "latitude"
    t.float  "longitude"
    t.string "zip_class"
  end

  add_index "zip_codes", ["city"], :name => "zip_codes_index_on_city"
  add_index "zip_codes", ["latitude"], :name => "zip_codes_index_on_latitude"
  add_index "zip_codes", ["longitude"], :name => "zip_codes_index_on_longitude"
  add_index "zip_codes", ["state"], :name => "zip_codes_index_on_state"
  add_index "zip_codes", ["zip"], :name => "zip_codes_index_on_zip"

end
