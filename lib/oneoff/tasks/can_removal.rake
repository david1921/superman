namespace :oneoff do

  desc "Change CAN country_code to CA"
  task :change_user_country_codes_from_can_to_ca => :environment do
    User.find_all_by_country_code("CAN").each do |user|
      user.country_code = "CA"
      user.save!
    end
  end

end
