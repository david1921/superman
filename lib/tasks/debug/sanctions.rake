namespace :debug do
  
  desc "Provide useful debugging info for the sanction file uploads"
  task :sanctions_uploads do
    %w{
      sanction_screening:export_and_uploaded_encrypted_advertiser_file
      sanction_screening:export_and_uploaded_encrypted_consumer_file
      sanction_screening:export_and_uploaded_encrypted_publisher_file
    }.each do |job_key|
      if last_finished_at = Job.last_finished_at(job_key)
        puts "#{job_key} last finished at #{last_finished_at}"
      else
        puts "#{job_key} has never been run"
      end
    end
  end

end
