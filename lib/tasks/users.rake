namespace :users do
  
  desc "Sets the has_accountant_privilege on specified admin users"
  task :setup_accountants => :environment do
    failed_to_update = []
    accountant_logins = [
      "oliver.gratry@analoganalytics.com",
      "todd.karpman@analoganalytics.com",
      "kathleen.winer@analoganalytics.com",
      "ken.kalb@analoganalytics.com",
      "tom.buscher@analoganalytics.com",
      "christinaliao",
      "glenn.veil"
    ]
    approver_logins = [
      "oliver.gratry@analoganalytics.com",
      "ken.kalb@analoganalytics.com",
      "glenn.veil"
    ]
    accountant_logins.each do |login|
      begin
        user = User.find(:first, :conditions => ["login=? and admin_privilege IS NOT NULL", login])
        if user.present?
          if approver_logins.include?(login)
            user.has_fee_sharing_agreement_approver_privilege = true
            puts "Set approver privilege on #{login}"
          end
          user.has_accountant_privilege = true
          if user.save(false) #not validating because ken has another user account with the same login
            puts "Updated #{login}"
          else
            failed_to_update << login
          end
        else
          failed_to_update << login
        end
      rescue
        puts "Error for: #{user.inspect} -- error #{$!}"
      end
    end
    puts "Could not update the following users: #{failed_to_update}" if failed_to_update.any?
  end
  
end