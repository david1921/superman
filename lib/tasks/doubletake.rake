namespace :doubletake do
  
  desc "Initialize the 'doubletakedeals' publisher with the production callback URLs"
  task :init_prod_config => :environment do
        puts "*" * 70
        puts "WARNING: This script does not configure the import URLs. You must edit "
        puts "upload_consumers_csv.yml manually for those."
        puts "*" * 70

        dt = Publisher.find_by_label("doubletakedeals")
        raise "couldn't find publisher with label 'doubletakedeals'" unless dt.present?

        config = dt.third_party_deals_api_config || ThirdPartyDealsApi::Config.new(:publisher_id => dt.id)
        config.update_attributes :api_username => "dtd@analoganalytics.com",
                                 :api_password => "23G8$!dsW", 
                                 :voucher_serial_numbers_url => "https://www.doubletakedeals.com/webservices/syndicatordealservice1.0.asmx/ProcessPurchase",
                                 :voucher_status_change_url => "https://www.doubletakedeals.com/webservices/syndicatordealservice1.0.asmx/VoucherStatusChangeNotification",
                                 :voucher_status_request_url => "https://www.doubletakedeals.com/webservices/syndicatordealservice1.0.asmx/GetVoucherStatus"    

        puts %Q{Successfully configured production Doubletake URLs.

Next up, import Doubletake's deals by running:

  RAILS_ENV=#{RAILS_ENV} rake import:daily_deals_via_http PUBLISHER_LABEL=doubletakedeals

    }
  end
  
  desc "Initialize the 'doubletakedeals' publisher with the stub callback URLs"
  task :init_stub_config => :environment do
    puts "*" * 70
    puts "WARNING: This script does not configure the import URLs. You must edit "
    puts "upload_consumers_csv.yml manually for those."
    puts "*" * 70
    dt = Publisher.find_by_label("doubletakedeals")
    raise "couldn't find publisher with label 'doubletakedeals'" unless dt.present?
    
    config = dt.third_party_deals_api_config || ThirdPartyDealsApiConfig.new(:publisher_id => dt.id)
    config.update_attributes :api_username => "dtd@analoganalytics.com",
                             :api_password => "23G8$!dsW", 
                             :voucher_serial_numbers_url => "http://localhost:4567/serial_numbers",
                             :voucher_status_change_url => "http://localhost:4567/voucher_status_change",
                             :voucher_status_request_url => "http://localhost:4567/voucher_status"
                             
    puts %Q{Successfully configured stub Doubletake URLs.

Run the following command to fire up the stub server:

  ./script/third_party_deals_api/stub_server.rb

Next up, import Doubletake's deals by running:

  RAILS_ENV=#{RAILS_ENV} rake import:daily_deals_via_http PUBLISHER_LABEL=doubletakedeals
  
}
  end
  
  desc "Initialize the 'doubletakedeals' publisher with the test callback URLs"
  task :init_test_config => :environment do
    puts "*" * 70
    puts "WARNING: This script does not configure the import URLs. You must edit "
    puts "upload_consumers_csv.yml manually for those."
    puts "*" * 70
    
    dt = Publisher.find_by_label("doubletakedeals")
    raise "couldn't find publisher with label 'doubletakedeals'" unless dt.present?
    
    config = dt.third_party_deals_api_config || ThirdPartyDealsApi::Config.new(:publisher_id => dt.id)
    config.update_attributes :api_username => "dtd@analoganalytics.com",
                             :api_password => "23G8$!dsW", 
                             :voucher_serial_numbers_url => "https://staging.doubletakedeals.com/webservices/syndicatordealservice1.0.asmx/ProcessPurchase",
                             :voucher_status_change_url => "https://staging.doubletakedeals.com/webservices/syndicatordealservice1.0.asmx/VoucherStatusChangeNotification",
                             :voucher_status_request_url => "https://staging.doubletakedeals.com/webservices/syndicatordealservice1.0.asmx/GetVoucherStatus"    
                             
    puts %Q{Successfully configured stub Doubletake URLs.

Next up, import Doubletake's deals by running:

  RAILS_ENV=#{RAILS_ENV} rake import:daily_deals_via_http PUBLISHER_LABEL=doubletakedeals

}
  end
  
  desc "Generate a CSV file of Doubletake voucher recipients and serial numbers"
  task :generate_recipients_and_serials_csv => :environment do
    filename = Doubletake.generate_recipients_and_serials_csv!
    puts "Exported Doubletake recipients and serials to #{filename}"
  end
  
  desc "Generate a CSV file of Doubletake purchase data"
  task :generate_purchases_csv do
    filename = Doubletake.generate_purchases_and_refunds_csv!
    puts "Exported Doubletake purchases to #{filename}"
  end
  
end