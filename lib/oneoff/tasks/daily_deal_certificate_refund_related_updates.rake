require File.expand_path("lib/oneoff/tasks/daily_deal_certificate_refund_related_updates", RAILS_ROOT)

namespace :oneoff do
  namespace :daily_deal_certificate do

    include DailyDealCertificateRefundRelatedUpdates

    desc "Runs through fully refunded and voided purchases marking their certs as 'refunded' or 'voided' as appropriate and updating refunded_at"
    task :update_refund_related_fields => :environment do
      puts "Marking certs as redeemed if they have been redeemed and have a status of 'active'..."
      updated = update_status_to_redeemed_for_redeemed_certs
      puts "  #{updated} certs as marked redeemed"
      total = 0
      puts "Marking certs for fully refunded purchases as 'refunded'"
      DailyDealPurchase.find_all_by_payment_status("refunded").each do |purchase|
        if full_refund?(purchase.actual_purchase_price, purchase.refund_amount)
          total += update_status_and_refund_as_appropriate(purchase, "refunded")
        end
      end
      puts "  #{total} certs marked refunded."
      total = 0
      puts "Marking certs for voided purchases as 'voided'"
      DailyDealPurchase.find_all_by_payment_status("voided").each do |purchase|
        total += update_status_and_refund_as_appropriate(purchase, "voided")
      end
      puts "  #{total} certs marked voided."
    end

  end


end
