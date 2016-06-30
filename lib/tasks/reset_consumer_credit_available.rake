require 'oneoff/reset_consumer_credit_available'

namespace :users do
  
  desc "Reset the credit available for all consumers for a given publisher"
  task :reset_credit_available_by_publisher, :publisher, :needs => :environment do |t, args|
    ResetConsumerCreditAvailable.run_for_publisher(args[:publisher])
  end

  desc "Reset the credit available for all consumers for a given publishing group"
  task :reset_credit_available_by_publishing_group, :publishing_group, :needs => :environment do |t, args|
    ResetConsumerCreditAvailable.run_for_publishing_group(args[:publishing_group])
  end
end