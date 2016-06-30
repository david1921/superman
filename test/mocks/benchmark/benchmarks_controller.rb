class BenchmarksController < ApplicationController
  def setup
    daily_deal = DailyDeal.find(4608)
    daily_deal.featured = false
    daily_deal.start_at = 1.day.ago
    daily_deal.hide_at = 1.day.from_now
    daily_deal.expires_on = 1.month.from_now
    daily_deal.save!

    User.destroy_all "login='Aladdin'"
    publisher = Publisher.find_by_label!("fortworthstartelegram")
    user = publisher.users.build(:login => "Aladdin", :email => "Aladdin@example.com")
    user.password = "secret"
    user.password_confirmation = "secret"
    user.save!

    User.destroy_all "login='admin'"
    user = User.new(:login => "admin", :email => "admin@example.com")
    user.password = "secret"
    user.password_confirmation = "secret"
    user.admin_privilege = User::FULL_ADMIN
    user.save!
    
    render :text => "OK"
  end
  
  def simulate_braintree_redirect
    sleep 0.3 + rand(10)
    redirect_to(thank_you_daily_deal_purchase_path(DailyDealPurchase.last))
  end
end
