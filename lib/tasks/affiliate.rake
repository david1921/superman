namespace :affiliate do

  desc "generate NUM of affiliate (subscriber_referrer_code) numbers, and spits them out to the console (defaut is 1)" 
  task :generate => :environment do
    
    current_count = SubscriberReferrerCode.count
    
    number_to_generate = (ENV['NUM'] || 1).to_i
    number_to_generate.times do 
      code = nil
      until code
        subscriber_referrer_code = SubscriberReferrerCode.create
        code = subscriber_referrer_code.valid? ? subscriber_referrer_code.code : nil
      end
      puts code
    end
    
    puts "generated #{SubscriberReferrerCode.count - current_count} affiliate(s)"
    
  end
  
end
