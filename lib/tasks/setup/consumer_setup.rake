#rake task to setup a consumer on a publisher
namespace :db do
  desc "add consumer to publisher"
  task :consumer_setup => :environment do
    raise "Can't run this rake task in production" if Rails.env.production?
    publisher = ARGV.last
    task publisher.to_sym
    delete_consumers(publisher)
    create_consumers(publisher)
    activate_consumers(publisher)
  end
end

def delete_consumers(publisher)
  this_publisher = Publisher.find_by_label(publisher)
  this_publisher.consumers.each do |consumer|
     consumer.delete if consumer.email.downcase.strip == "a@b.com"
  end
end

def create_consumers(publisher)
  this_publisher = Publisher.find_by_label(publisher)
        consumer = this_publisher.consumers.create(
                    :name => ['Mr.', 'Mrs.'].sample + ' Analog',
                    :email => 'a@b.com',
                    :password =>'analog',
                    :password_confirmation =>'analog',
                    :agree_to_terms => 1)
  consumer.save
end

def activate_consumers(publisher)
  Consumer.last.activate!
  puts "Consumer created and activated for -- #{publisher}"
  puts "Username: a@b.com / Password: analog"
end