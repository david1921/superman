namespace :data do

  desc "Invalid records"
  task :invalid_records, :needs => :environment do
    CLASSES_TO_CHECK = [ Advertiser, Consumer, DailyDealPurchase, DailyDeal, EmailRecipient, GiftCertificate, MarketZipCode, Offer, PurchasedGiftCertificate, TxtOffer]

    CLASSES_TO_CHECK.each do |c|
      c.all(:limit => 1000, :order => "id DESC").each do  |record|
        if !record.valid? 
          puts "#{c.to_s} id #{record.id} is not valid."
        end
      end
    end
  end

end
