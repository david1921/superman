namespace :coupon_change_notice do
  desc "Generate coupon change notice for PUBLISHER or PUBLISHING_GROUP"
  task :generate => :environment do
    publishers = case
      when name = ENV['PUBLISHING_GROUP']
        PublishingGroup.find_by_name(name).publishers
      when name = ENV['PUBLISHER']
        [ Publisher.find_by_name(name) ]
      else
        raise "Must set PUBLISHING_GROUP or PUBLISHER"
    end

    Time.zone = "Pacific Time (US & Canada)"
    today_pst = Time.zone.now.to_date
    tomorrow_pst = today_pst.tomorrow

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_name = "#{today_pst.to_formatted_s(:db)}-analog-coupon-change-notice.txt"

    File.open(File.expand_path(file_name, file_base), "w") do |io|
      OfferChangeNotice.generate_head do |row|
        io.write("#{row}\r\n")
      end
      publishers.each do |publisher|
        OfferChangeNotice.new(publisher, tomorrow_pst).generate_data do |row|
          io.write("#{row}\r\n")
        end
      end
    end
  end

  desc "Upload today's file to DESTINATION via FTP"
  task :upload => :environment do
    require "net/ftp"

    Time.zone = "Pacific Time (US & Canada)"
    today_pst = Time.zone.now.to_date
    tomorrow_pst = today_pst.tomorrow

    file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
    file_name = "#{today_pst.to_formatted_s(:db)}-analog-coupon-change-notice.txt"
    file_path = File.expand_path(file_name, file_base)
    raise "Change file '#{file_path}' does not exist" unless File.exists?(file_path)
    raise "Change file '#{file_path}' isn't readable" unless File.readable?(file_path)

    raise "DESTINATION must be set" unless destination = ENV['DESTINATION']
    destination = ("ftp://" + destination.to_s) unless destination.starts_with?("ftp://")
    _, user_pass, host, port, _, path = URI.split(destination)
    raise "Can't parse DESTINATION" unless host
    port ||= 21
    user, pass = user_pass.to_s.split(':')
    user ||= "anonymous"
    pass ||= "support@analoganalytics.com"
    
    ftp = Net::FTP.new
    ftp.connect(host, port)
    ftp.login(user, pass)
    ftp.chdir(path) if path.present?
    ftp.putbinaryfile(file_path)
    ftp.close
    
    ftp.connect(host, port)
    ftp.login(user, pass)
    ftp.chdir(path) if path.present?
    lines = ftp.list
    ftp.close
    line = lines.detect { |line| line =~ /\s#{Regexp.quote(file_name)}$/ }
    raise "Can't find #{file_name} in listing" unless line
    Rails.logger.info line
  end
end
