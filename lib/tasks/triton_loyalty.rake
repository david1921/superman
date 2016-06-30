namespace :triton_loyalty do
  desc "Update remote list for PUBLISHER_LABEL"
  task :update_list => :environment do
    raise "Must set PUBLISHER_LABEL" unless label = ENV['PUBLISHER_LABEL']
    raise "No pubisher with label '#{label}'" unless (publisher = Publisher.find_by_label(label))

    stats = publisher.update_triton_loyalty_list!

    number, errors = stats.values_at(:number, :errors)
    Rails.logger.info "#{number} records updated"

    if errors.present?
      puts
      puts "ERRORS"
      errors.each_with_index { |error, index| puts "#{'%3d' % index}. #{error}" }
    end
  end
end
