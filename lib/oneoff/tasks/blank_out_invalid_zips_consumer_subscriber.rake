
namespace :oneoff do
  task :blank_out_invalid_zips_for_consumers => :environment do |t|

    class Validator
      include Addresses::Validations
    end

    processed = 0
    blanked = []
    problematic = 0
    blank_already = 0
    problem_signups = []
    bogus_country_codes = Set.new
    puts "#{Consumer.count} consumers to process."
    validator = Validator.new
    Consumer.find_each do |signup|
      if signup.zip_code?
        regex = validator.postal_code_regex(signup.country_code)
        if regex.present?
          unless regex =~ signup.zip_code
            unless signup.zip_code_required?
              bad_zip = signup.zip_code
              signup.zip_code = ""
              if signup.save
                blanked << bad_zip
              else
                problem_signups << signup
              end
            else
              problematic += 1
            end
          end
        else
          bogus_country_codes << signup.country_code
        end
      else
        blank_already += 1
      end
      processed += 1
      puts "#{processed} processed" if processed % 1000 == 0
    end
    puts "processed a total of #{processed} consumers"
    puts "#{blank_already} zip_codes were blank already"
    puts "blanked out zip_codes for #{blanked.size} consumers: #{blanked.inspect}"
    puts "#{problematic} zip_codes cannot be blank but do not validate"
    puts "#{bogus_country_codes.size} bogus country codes:  #{bogus_country_codes.inspect}"
    puts "#{problem_signups.size} signups could not be saved after blanking out zip"
    problem_signups.each do |problem|
      puts "#{problem.id} - #{problem.errors.full_messages.inspect}"
    end
  end

  task :blank_out_invalid_zips_for_subscribers => :environment do |t|
    class Validator
      include ::Address::Validations
    end

    processed = 0
    blanked = []
    blank_already = 0
    bad_zips = {}
    problem_signups = []
    puts "#{Subscriber.count} subscribers to process."
    validator = Validator.new
    Subscriber.find_each do |signup|
      if signup.zip_code.present?
        unless [validator.us_regex, validator.ca_regex, validator.uk_regex].detect {|regex| regex =~ signup.zip_code}
          bad_zips[signup.publisher.label] ||= 0
          bad_zips[signup.publisher.label] += 1
          bad_zip = signup.zip_code
          signup.zip_code = ""
          if signup.save
            blanked << bad_zip
          else
            problem_signups << signup
          end
        end
      else
        blank_already += 1
      end
      processed += 1
      puts "#{processed} processed" if processed % 10000 == 0
    end
    puts "processed a total of #{processed} subscribers"
    puts "#{blank_already} zip_codes were blank already"
    puts "blanked out zip_codes for #{blanked.size} subscribers: #{blanked.inspect}"
    bad_zips.each { |publisher, count| puts "#{publisher} #{count}" }
    puts "#{problem_signups.size} signups could not be saved after blanking out zip"
    problem_signups.each do |problem|
      puts "#{problem.id} - #{problem.errors.full_messages.inspect}"
    end
  end


end
