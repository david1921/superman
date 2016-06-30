namespace :oneoff do
  namespace :duplicate_serial_numbers do
    desc "regenerate serial numbers for duplicate serial numbers"
    task :regenerate => :environment do
      create_duplicate_serial_number_tmp_table
      puts "Regenerating serial_numbers for DailyDealCertificates that have serial_numbers that other DailyDealCertificates are using..."
      regenerate_duplicate_daily_deal_certificate_serial_numbers
      puts "Regenerating serial_numbers for DailyDealCertificates that have serial_numbers that PurchasedGiftCertificates are using..."
      regenerate_duplicate_daily_deal_certificate_serial_numbers_that_collide_with_purchased_gift_certificates
    end
  end
end

private
def create_duplicate_serial_number_tmp_table
  ActiveRecord::Base.connection.create_table("duplicate_serial_numbers", :temporary => true) do |t|
    t.string :serial_number
  end
  ActiveRecord::Base.connection.execute("insert into duplicate_serial_numbers (serial_number)
                                                select serial_number collate utf8_unicode_ci
                                                  from daily_deal_certificates group by serial_number
                                                  having count(serial_number) > 1;")
end

def regenerate_serial_number(certificate)
  old_serial_number = certificate.serial_number
  new_serial_number = certificate.unique_random_serial_number
  # the serial number rightly validates immutability
  # so we work around that here with an update_attribute
  certificate.update_attribute(:serial_number, new_serial_number)
  puts "  Duplicate serial_number for #{certificate.class.name} - #{certificate.id} was #{old_serial_number} but now is #{new_serial_number}."
end

def regenerate_duplicate_daily_deal_certificate_serial_numbers
  certificate_ids = Set.new
  total_count = 0
  regenerated_count = 0
  ActiveRecord::Base.connection.execute("select daily_deal_certificates.id, daily_deal_certificates.serial_number from daily_deal_certificates
                                                inner join duplicate_serial_numbers on daily_deal_certificates.serial_number collate utf8_general_ci = duplicate_serial_numbers.serial_number collate utf8_general_ci
                                                inner join daily_deal_purchases on daily_deal_purchase_id = daily_deal_purchases.id
                                                inner join daily_deals on daily_deal_purchases.daily_deal_id = daily_deals.id
                                                inner join publishers on daily_deals.publisher_id = publishers.id
                                                  order by daily_deal_purchases.executed_at DESC;").each_hash do |row|
    if certificate_ids.include?(row["serial_number"])
      # we've seen it already so we need to regenerate because it's a duplicate
      regenerate_serial_number(DailyDealCertificate.find(row["id"]))
      regenerated_count += 1
    end
    certificate_ids << row["serial_number"]
    total_count += 1
  end
  puts "Regenerated #{regenerated_count} of a total of #{total_count}"
end

def regenerate_duplicate_daily_deal_certificate_serial_numbers_that_collide_with_purchased_gift_certificates
  total_count = 0
  ActiveRecord::Base.connection.execute("select daily_deal_certificates.id, daily_deal_certificates.serial_number from daily_deal_certificates
                                            inner join purchased_gift_certificates on daily_deal_certificates.serial_number = purchased_gift_certificates.serial_number;").each_hash do |row|
    regenerate_serial_number(DailyDealCertificate.find(row["id"]))
    total_count += 1
  end
  puts "Regenerated #{total_count} serial_numbers"
end


