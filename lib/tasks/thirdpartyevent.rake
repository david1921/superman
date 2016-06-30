namespace :thirdpartyevent do
  desc "Get a csv of the data from a certain target id"
  task :report_by_target_id do |task, args|
    raise "TARGET_ID is required" unless ENV['TARGET_ID'].present?
    deal_id = ENV['TARGET_ID']
    events = ThirdPartyEvent.find(:all, :conditions => "target_id = #{deal_id}")
    # sql = 
    # 
    # select dd.id as 'Deal ID', dd.price, DATE(tpe.created_at) AS 'Date', publishers.label as 'Market', COUNT(tpe.id) AS 'Saw Lightbox', COUNT(s.id) AS 'Submitted Email'
    # from third_party_events tpe   
    #   inner join daily_deals dd ON dd.id = tpe.target_id   
    #   inner join publishers ON publishers.id = dd.publisher_id 
    #   left join third_party_events s ON  s.session_id  = tpe.session_id AND DATE(tpe.created_at) = DATE(s.created_at) AND s.action = 'lightbox-submit'
    #   WHERE tpe.action = 'lightbox' AND DATE(tpe.created_at) > '2012-04-17' 
    # GROUP BY dd.id ,DATE(tpe.created_at), publishers.label
    # ORDER BY DATE(tpe.created_at), publishers.label
    
    
    
    
  end
  desc "Get a csv of the data for a particular publisher"
  task :report_by_publisher_id => :environment do
    raise "PUBLISHER_LABEL is required" unless ENV['PUBLISHER_LABEL'].present?
    publisher = Publisher.find_by_label(ENV['PUBLISHER_LABEL'])
    events = ThirdPartyEvent.find(:all, :conditions => "target_id = #{deal_id}")
    
    
     header = ["Customer ID", "Market", "First Name", "Last Name", "Email", "Address", "Address 2", "Zip Code", "Last Updated At"]
      FasterCSV.open(file_path, "w", :force_quotes => true) do |csv|
        csv << header
      
      
      end
        
  end 
  
end
# Helpers
def unique_file_path(name = 'EXPORT', ext = ".csv")  
  file_name = name << '-' << Time.now.localtime.strftime("%Y%m%d-%H%M%S") << ext
  File.expand_path(file_name, File.expand_path("tmp", Rails.root))
end
def upload_file_to_publisher(file_path, label)
  publishers_config = UploadConfig.new(:publishing_groups) 
  config = publishers_config.fetch!(label)
  if config.nil?
    publishers_config = UploadConfig.new(:publishers)
    config = publishers_config.fetch!(label)
  end
  Uploader.new(publishers_config).upload(label, file_path)  
end