def create_consumer(publisher, name, email)
  consumer = publisher.consumers.build(:name => name, :email => email)
  consumer.password = consumer.password_confirmation = "16KSn0T2kcw7SkFT"
  consumer.need_setup = true
  consumer.purchase_credit = 10.0
  consumer.deal_credit_applied = true
  if consumer.save
    puts "Created consumer #{name}, #{email}"
    consumer
  else
    puts "Consumer #{email}: #{consumer.errors.full_messages.join(', ')}"
    nil
  end
end

namespace :freedom do
  desc "Create consumers with preset purchase credit"
  task :create_consumers => :environment do
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    publisher = Publisher.find_by_label!(label)
    
    FasterCSV.open(File.expand_path("tmp/consumers.out.csv", Rails.root), "w", :row_sep => "\r\n") do |row_w|
      row_w << ["id", "full_name", "email", "url"]
      FasterCSV.foreach(File.expand_path("tmp/consumers.in.csv", Rails.root), :headers => true) do |row_r|
        if (consumer = create_consumer(publisher, row_r["full_name"], row_r["email"]))
          url = "http://dealoftheday.#{publisher.label}.com/su/#{publisher.id}/#{consumer.perishable_token}"
          row_w << [row_r["id"], consumer.name, consumer.email, url]
        end
      end
    end
  end
end
