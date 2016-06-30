namespace :coupons do
  desc "Download LOCM update files from SOURCE for DATE (optional)"
  task :download_updates => :environment do
    require "net/ftp"

    file_prefixes = [ "AAListingFullList", "AAPartnerSiteLoginUpdate" ]

    raise "SOURCE must be set" unless source = ENV['SOURCE']
    source = ("ftp://" + source.to_s) unless source.starts_with?("ftp://")
    _, user_pass, host, port, _, path = URI.split(source)
    raise "Can't parse SOURCE" unless host
    port ||= 21
    user, pass = user_pass.to_s.split(':')
    user ||= "anonymous"
    pass ||= "support@analoganalytics.com"

    Net::FTP.open(host, user, pass) do |ftp|
      file_prefixes.each do |file_prefix|
        ftp.getbinaryfile(import_file_name(file_prefix), import_file_path(file_prefix))
      end
    end
  end
  
  desc "Import LOCM updates files for DATE (optional)"
  task :import_updates => [ :import_listings, :import_logins ]
  
  task :import_listings => :environment do
    Advertiser.import import_file_path("AAListingFullList")
  end
  
  task :import_logins => :environment do
    errors = []

    created_publishers_count = 0
    created_users_count = 0

    Publisher.transaction do
      publishing_group = PublishingGroup.find_or_create_by_name("Local.com")
      publishing_group.save!
      row_index = 1

      converted_text = Iconv.iconv("UTF-8", "WINDOWS-1252", File.read(import_file_path("AAPartnerSiteLoginUpdate"))).join
      FasterCSV.parse(converted_text, :headers => true) do |row|
        status = row["Status"]
        publisher_label = row["SiteID"]
        publisher_name = row["SiteName"]
        user_login = row["LoginEmail"]

        case status
        when "A"
          if publisher = Publisher.find_by_label(publisher_label)
            if publisher.name != publisher_name
              errors << "Publisher #{publisher.label} has name #{publisher.name} but import file has #{publisher_name} on row #{row_index}"
            end
          elsif publisher = Publisher.find_by_name(publisher_name)
            errors << "Publisher #{publisher.name} has label #{publisher.label} but import file has #{publisher_label} on row #{row_index}"
          else
            publisher = publishing_group.publishers.create!(
              :name => publisher_name,
              :label => publisher_label,
              :self_serve => true,
              :can_create_advertisers => false,
              :advertiser_has_listing => true,
              :default_offer_search_distance => 10
            )
            created_publishers_count += 1
          end

          if user = User.find_by_login(user_login)
            if user.company != publisher
              errors << "User #{user.id} has company #{user.company_type}/#{user.company_id} but import file has #{publisher.name} on row #{row_index}"
            end
          else
            publisher.users.create!(
              :login => row["LoginEmail"],
              :label => row["MemberID"],
              :password => "ZL0P0mHkf177", 
              :password_confirmation => "ZL0P0mHkf177"
            )
            created_users_count += 1
          end
        when "D"
          if publisher = Publisher.find_by_label(publisher_label)
            publisher.destroy
          else
            errors << "Could not destroy Publisher with label '#{publisher_label}'. Label not found on row #{row_index}."
          end
        when "U"
          if publisher = Publisher.find_by_label(publisher_label)
            if publisher.name != publisher_name
              errors << "Publisher #{publisher.label} has name #{publisher.name} but import file has #{publisher_name} on row #{row_index}"
            end
          elsif publisher = Publisher.find_by_name(publisher_name)
            errors << "Publisher #{publisher.name} has label #{publisher.label} but import file has #{publisher_label} on row #{row_index}"
          else
            publisher = publishing_group.publishers.create!(
              :name => publisher_name,
              :label => publisher_label,
              :self_serve => true,
              :can_create_advertisers => false,
              :advertiser_has_listing => true,
              :default_offer_search_distance => 10
            )
            created_publishers_count += 1
          end
        
    if user = User.find_by_login(user_login)
              if user.company != publisher
                errors << "User #{user.id} has company #{user.company_type}/#{user.company_id} but import file has #{publisher.name} on row #{row_index}"
              end
             user.update_attributes!(:label => row["MemberID"])
            else
              publisher.users.create!(
                :login => user_login,
                :password => "ZL0P0mHkf177", 
                :label => row["MemberID"],
                :password_confirmation => "ZL0P0mHkf177"
              )
              created_users_count += 1
            end
        else
          errors << "Unknown Status '#{status}' on row #{row_index}"
        end

        if row_index % 10 == 0
          STDOUT.write row_index
        end
        STDOUT.write "."
        STDOUT.flush

        row_index = row_index + 1
      end
      puts
      puts "Created #{created_publishers_count} publishers, #{created_users_count} users"
    end

    puts
    errors.each { |error| puts error }
  end
end

def import_file_name(prefix)
  "#{prefix}_#{import_date.to_s(:number)}.csv"
end

def import_file_path(prefix)
  file_base = ENV['DIRECTORY'] || File.expand_path("tmp", Rails.root)
  File.expand_path("#{import_file_name(prefix)}", file_base)  
end

def import_date
  Time.zone = "Pacific Time (US & Canada)"
  if ENV["DATE"]
    Time.zone.parse(ENV["DATE"]).to_date
  else
    Time.zone.now.to_date
  end
end
