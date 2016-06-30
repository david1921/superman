namespace :oneoff do
  namespace :fixconsumers do
    task :unassimilate => :environment do
      #  the following dump came from an older prod dump
      emitchell_attr_yaml = <<-EOS
name: "Ellen Mitchell"
email: "emitchell@westfam.com"
crypted_password: "72c3b87e6441ef9157271d5d7106cde36a0ea226"
salt: "8jxdAZEUHe8tXsEe"
created_at: "2011-12-08 17:10:43"
updated_at: "2011-12-09 05:20:35"
session_timeout: "0"
login: "emitchell@westfam.com"
perishable_token: "AIUQiQMMBtANoYZ7"
publisher_id: "289"
type: "Consumer"
first_name: "Ellen"
last_name: "Mitchell"
activation_code: "90VyCDTI"
activated_at: "2011-12-08 17:11:07"
agree_to_terms: "1"
need_setup: "0"
credit_available: "0.00"
referrer_code: "6d844a53-2e4b-4d40-851a-5ae161e1cf52"
bit_ly_url: "http://bit.ly/vFD5pT"
remote_record_id: "30969753"
remote_record_updated_at: "2011-12-09 05:20:35"
user_agent: "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0; SLCC1; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.5.30729; .NET CLR 1.1.4322; .NET CLR 3.0.30729; MS-RTC EA 2)"
allow_syndication_access: "0"
preferred_locale: "en"
force_password_reset: "0"
has_accountant_privilege: "0"
has_fee_sharing_agreement_approver_privilege: "0"
failed_login_attempts: "0"
can_manage_consumers: "0"
in_vault: "0"
EOS
    emitchell_attr = YAML::load(emitchell_attr_yaml)
    emitchell = Consumer.create(emitchell_attr)
    emitchell_purchases = DailyDealPurchase.find(:all, :conditions => 'id in (833675, 958336)')
    emitchell.assimilate_daily_deal_purchases(emitchell_purchases)
    
    end
  end
end