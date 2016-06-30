namespace :suspected_frauds do
  desc "Regenerate suspected-fraud entries for DAILY_DEAL_ID at score THRESHOLD [0.6]"
  task :regenerate => :environment do
    raise "DAILY_DEAL_ID is required" unless (daily_deal_id = ENV['DAILY_DEAL_ID'])
    raise "DailyDeal '#{daily_deal_id}' not found" unless (daily_deal = DailyDeal.find_by_id(daily_deal_id))
    threshold = (ENV['THRESHOLD'].if_present || 0.6).to_f
    
    daily_deal.regenerate_suspected_frauds(threshold)
  end
    
  desc "Export a previously generated suspected-fraud list for DAILY_DEAL_ID as a CSV"
  task :export  => :environment do
    raise "DAILY_DEAL_ID is required" unless (daily_deal_id = ENV['DAILY_DEAL_ID'])
    raise "DailyDeal '#{daily_deal_id}' not found" unless (daily_deal = DailyDeal.find_by_id(daily_deal_id))

    csv_path = File.expand_path("tmp/suspected-frauds-#{daily_deal.id}.csv", RAILS_ROOT)
    FasterCSV.open(csv_path, "w", :force_quotes => true) do |csv|
      csv << %w{
        fraud_score
        purchase_id
        purchase_consumer_name
        purchase_consumer_email
        purchase_ip_address
        purchase_credit_card_last_4
        purchase_amount_paid
        purchase_purchase_price
        purchase_credits_used
        matching_purchase_id
        matching_consumer_name
        matching_consumer_email
        matching_ip_address
        matching_credit_card_last_4
        matching_amount_paid
        matching_purchase_price
        matching_credits_used
      }
      daily_deal.suspected_frauds.find_each do |suspected_fraud|
        purchase = DailyDealPurchase.find(suspected_fraud.suspect_daily_deal_purchase, :include => [:consumer, :daily_deal_payment])
        matching = DailyDealPurchase.find(suspected_fraud.matched_daily_deal_purchase, :include => [:consumer, :daily_deal_payment])
        csv << [
          suspected_fraud.score,
          purchase.id,
          purchase.consumer.name,
          purchase.consumer.email,
          purchase.ip_address,
          purchase.daily_deal_payment.try(:credit_card_last_4),
          suspect.daily_deal_payment.try(:amount),
          suspect.actual_purchase_price,
          suspect.credit_used,
          matching.id,
          matching.consumer.name,
          matching.consumer.email,
          matching.ip_address,
          matching.daily_deal_payment.try(:credit_card_last_4),
          matched.daily_deal_payment.try(:amount),
          matched.actual_purchase_price,
          matched.credit_used
        ]
      end
    end
  end

  desc "Generate suspected-fraud entries as a job for PUBLISHER_LABEL at score THRESHOLD [0.6]"
  task :generate_job => :environment do
    raise "PUBLISHER_LABEL is required" unless (publisher_label = ENV['PUBLISHER_LABEL'])
    raise "Publisher '#{publisher_label}' not found" unless (publisher = Publisher.find_by_label(publisher_label))

    threshold = ENV['THRESHOLD'].if_present || "0.6"
    raise "THRESHOLD must be a number between 0.0 and 1.0" unless (threshold = threshold.to_f rescue nil) && 0.0 < threshold && threshold < 1.0
    
    publisher.generate_suspected_frauds threshold
  end
  
  desc "Export results of the last suspected-frauds job for PUBLISHER_LABEL as a CSV"
  task :export_last_job  => :environment do
    raise "PUBLISHER_LABEL is required" unless (publisher_label = ENV['PUBLISHER_LABEL'])
    raise "Publisher '#{publisher_label}' not found" unless (publisher = Publisher.find_by_label(publisher_label))

    csv_path = File.expand_path("tmp/suspected-frauds-#{publisher.label}.csv", RAILS_ROOT)
    FasterCSV.open(csv_path, "w", :force_quotes => true) do |csv|
      csv << %w{
        fraud_score
        purchase_id
        purchase_consumer_name
        purchase_consumer_email
        purchase_ip_address
        purchase_credit_card_last_4
        purchase_amount_paid
        purchase_purchase_price
        purchase_credits_used
        matching_purchase_id
        matching_consumer_name
        matching_consumer_email
        matching_ip_address
        matching_credit_card_last_4
        matching_amount_paid
        matching_purchase_price
        matching_credits_used
      }
      publisher.with_suspected_frauds_from_last_job do |suspected_fraud|
        suspect = suspected_fraud.suspect_daily_deal_purchase
        matched = suspected_fraud.matched_daily_deal_purchase
        csv << [
          suspected_fraud.score,
          suspect.id,
          suspect.consumer.name,
          suspect.consumer.email,
          suspect.ip_address,
          suspect.daily_deal_payment.try(:credit_card_last_4),
          suspect.daily_deal_payment.try(:amount),
          suspect.actual_purchase_price,
          suspect.credit_used,
          matched.id,
          matched.consumer.name,
          matched.consumer.email,
          matched.ip_address,
          matched.daily_deal_payment.try(:credit_card_last_4),
          matched.daily_deal_payment.try(:amount),
          matched.actual_purchase_price,
          matched.credit_used
          
        ]
      end
    end
  end
end
