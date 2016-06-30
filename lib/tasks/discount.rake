namespace :discount do

  desc "delete all discounts for a publisher"
  task :delete_all_for_publisher => :environment do
    
    raise "please supply ENV['label']=publisher_label for this task" unless ENV['label']

    if publisher = Publisher.find_by_label(ENV['label'])
      unless publisher.signup_discount.nil?
        publisher.signup_discount.delete
      else puts "There are no discounts for publisher: #{publisher.label}"; end
    else raise "There is no publisher w/ that label"; end
  end

  desc "add singup credit for specified publisher"
  task :signup_credit => :environment do

    raise "please supply ENV['label']=publisher_label for this task" unless ENV['label']
    raise "please supply ENV['credit']=credit for this task" unless ENV['credit']

    if publisher = Publisher.find_by_label(ENV['label'])
      discount = Discount.new
      discount.publisher = publisher
      discount.code = "SIGNUP_CREDIT"
      discount.amount = ENV['credit']
      discount.save!
    else raise "There is no publisher w/ that label"; end

  end
  
end
