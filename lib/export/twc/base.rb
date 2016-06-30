module Export
  
  module Twc
    
    class Base < ::Export::Base
      
      class << self
        
        def upload_file_to_ftp_server(filename)
          ensure_file_exists!(filename)
          Uploader.new(UploadConfig.new(:publishers)).upload("clickedin", filename)
        end
        
        
        def publishing_group_label
          "rr"
        end
        
      end
      
    end
    
  end
  
end