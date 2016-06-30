module QrCode
  DEFAULT_OUTPUT_FORMAT = :png
  VALID_RQR_OPTIONS = [:level, :version, :module_size, :output_format]

  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods
    def with_qr_code_image(code, options = {})
      rqr_options = options.slice(*VALID_RQR_OPTIONS)
      format = options.delete(:output_format) || DEFAULT_OUTPUT_FORMAT

      qr = RQR::QRCode.new(rqr_options)
      begin
        qr.save(code, qr_code_file_path, format)
        if block_given?
          File.open(qr_code_file_path) { |file| yield file }
        end

        options[:keep_file] ? qr_code_file_path : File.unlink(qr_code_file_path)
      rescue RQR::ImageException => e
        # notify exceptional and carry on
        Exceptional.handle(e)
      end
    end
    
    private
    
    def qr_code_file_path
      @qr_code_file_path ||= File.expand_path("#{self.class.name.underscore}-#{id}-qr", "#{Rails.root}/tmp")
    end
  end
end
