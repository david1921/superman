module Export
  
  module Entercom
    
    class Base < ::Export::Base
      
      class << self

        def upload_file_to_ftp_server(filename)
          ensure_file_exists!(filename)
        
          Uploader.new("entercom" => {
            :host => "209.208.243.10",
            :user => "analoganalytics",
            :pass => "1muIs8DLCt",
            :protocol => "sftp"
          }).upload("entercom", filename)
        end
      
        def publishing_group_label
          "entercomnew"
        end
        
      end
      
    end
    
  end
  
end
