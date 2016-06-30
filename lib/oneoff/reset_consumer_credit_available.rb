module ResetConsumerCreditAvailable

  def self.run_for_publishing_group(label)
    publishingGroup = PublishingGroup.find_by_label(label)
    if publishingGroup
      publishingGroup.publishers.each do |publisher|
        reset_consumers(publisher)
      end
    else
      puts "PublishingGroup with label '#{label}' not found"
    end
  end

  def self.run_for_publisher(label)
    publisher = Publisher.find_by_label(label)
    if publisher
      reset_consumers(publisher)
    else
      puts "Publisher with label '#{label}' not found"
    end
  end

  def self.reset_consumers(publisher)
    puts "Reseting credit available for publisher #{publisher.id}."
    Consumer.find_each(:conditions => { :credit_available_reset_at => nil, :publisher_id => publisher.id }) do |consumer|
      begin
        consumer.reset_credit_available
        consumer.save
        puts "Consumer #{consumer.id} new credit_available: #{consumer.credit_available}."
      rescue => e
        puts "Error for: #{consumer.inspect} -- error #{e.message}"
      end
    end
  end
end
