namespace :oneoff do
  namespace :countries do

    desc "load ido 3166 countries into countries table as needed"
    task :load_countries => :environment do
      File.open(File.expand_path("lib/oneoff/tasks/data/countries.txt", RAILS_ROOT)) do |f|
        while line = f.gets
          if line =~ /(.*)([A-Z]{2})$/
            country_name = $1.strip.titleize
            country_code = $2.strip
            country = Country.find_by_code(country_code)
            if country
              puts "Skipping: #{country_name}"
            else
              puts "Making (inactive): #{country_name}"
              Country.create!(:name => country_name, :code => country_code, :active => false)
            end
          end
        end
      end
    end

    desc "clean up some country data"
    task :cleanup => :environment do
      us = Country::US
      us.phone_number_length = 10
      us.calling_code = "1"
      us.save!
      uk = Country::UK
      uk.phone_number_length = 11
      uk.calling_code = "44"
      uk.save!
      ca = Country::CA
      ca.phone_number_length = "10"
      ca.calling_code = 1
      ca.save!
    end
  end

end

