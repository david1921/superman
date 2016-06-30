module Export
  
  module Twc
    
    class Signups < ::Export::Twc::Base
      
      job_key "twc:generate_signups_csv"
      
      include Export::Signups
      
      column "first_name" => :first_name
      column "last_name" => :last_name
      column "e_mail" => :email
      column "zip_code" => :zip_code
      column "created_at" => lambda { |row| format_datetime_as_iso8601(row["signup_date"]) }
      column "device" => :device
    end
    
  end
  
end