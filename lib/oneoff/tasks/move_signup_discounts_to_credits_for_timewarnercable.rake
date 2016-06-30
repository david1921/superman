namespace :oneoff do
  
  desc "move the signup discounts to signup credits for time warner cable"
  task :move_signup_discounts_to_credits_for_timewarnercable do
    dry_run = ENV["DRY_RUN"].present?
    PublishingGroup.find_by_label!("rr").publishers.each do |publisher|
      total_consumers_with_signup_discounts = 0
      total_consumers_updated               = 0
      publisher.consumers.each do |consumer|        
        credit_amount = 0.00
        if consumer.signup_discount
          if consumer.signup_discount.amount > 0
            total_consumers_with_signup_discounts += 1
            if consumer.daily_deal_purchases.present?
              consumer.daily_deal_purchases.each do |purchase|
                if purchase.discount.present?
                  credit_amount = purchase.discount.amount - purchase.daily_deal.price
                  credit_amount = 0.00 if credit_amount < 0
                end
              end
            else
              credit_amount = consumer.signup_discount.amount
            end
          end
        end
        if credit_amount > 0
          if dry_run
            total_consumers_updated += 1
            puts "  would update #{consumer.email} to have a credit of #{credit_amount}"
          else
            if consumer.send(:adjust_credit_available!, credit_amount)
              total_consumers_updated += 1
              puts "  updated #{consumer.email}, now has a credit of #{consumer.credit_available}"
              consumer.signup_discount = nil
              unless consumer.save
                puts "  [ERROR] unable to remove signup discount from #{consumer.email}"
              end              
            else
              puts "  [ERROR] unable to adjust credit for #{consumer.email}"
            end            
          end
        end
      end
      if dry_run
        puts ">>> [DRY-RUN] Would have updated #{total_consumers_updated} of #{total_consumers_with_signup_discounts} consumers with signup discounts for #{publisher.name}\n\n"
      else
        puts ">>> Updated #{total_consumers_updated} of #{total_consumers_with_signup_discounts} consumers with signup discounts for #{publisher.name}\n\n"
      end
    end
    
    
  end
  
end

