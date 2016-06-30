namespace :oneoff do
  namespace :travelsavers do
    task :fix_certificate_statuses_for_refunds do
      doit = ENV["DOIT"] == "1"
      unless doit
        puts "** This is a DRY RUN. ** Run this script with DOIT=1 to actually update the database."
      end
      ts_purchases = TravelsaversBooking.all.map(&:daily_deal_purchase)
      ts_purchases.each do |p|
        next unless p.present? && p.refunded? && p.daily_deal_certificates.any? { |c| !c.refunded? }
        non_refunded_certs = p.daily_deal_certificates.select { |c| !c.refunded? }

        non_refunded_certs.each do |cert|
          if doit
            print "Refunding DailyDealCertificate #{cert.id} (current status: #{cert.status})..."
            cert.refund!
            puts "done."
          else
            puts "[DRY RUN] Would have refunded DailyDealCertificate #{cert.id}. (current status: #{cert.status}) "
          end
        end
      end
    end
  end
end
