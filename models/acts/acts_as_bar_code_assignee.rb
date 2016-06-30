module ActsAsBarCodeAssignee
  VALID_BAR_CODE_OPTIONS = [
    :encoding_format,
    :output_format,
    :width,
    :height,
    :scaling_factor,
    :xoff,
    :yoff,
    :margin,
    :resolution,
    :antialias,
    :keep_jpg,
    :no_ascii
  ]
  DEFAULT_BAR_CODE_ENCODING_FORMAT = Gbarcode::BARCODE_128B
  DEFAULT_BAR_CODE_OUTPUT_FORMAT ="jpg"

  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods
    def with_bar_code_image(code, options={})
      options[:encoding_format] = DEFAULT_BAR_CODE_ENCODING_FORMAT unless options[:encoding_format]
      options[:output_format] = DEFAULT_BAR_CODE_OUTPUT_FORMAT unless options[:output_format]
      options.assert_valid_keys VALID_BAR_CODE_OPTIONS
      
      bc = Gbarcode.barcode_create(code.upcase)
      bc.width = options[:width] if options[:width]
      bc.height = options[:height] if options[:height]
      bc.scalef = options[:scaling_factor] if options[:scaling_factor]
      bc.xoff = options[:xoff] if options[:xoff]
      bc.yoff = options[:yoff] if options[:yoff]
      bc.margin = options[:margin] if options[:margin]
      Gbarcode.barcode_encode(bc, options[:encoding_format])
      
      File.open(barcode_eps_file_path, "w+") do |eps_file|
        print_options = options[:no_ascii] ? (Gbarcode::BARCODE_OUT_EPS | Gbarcode::BARCODE_NO_ASCII) : Gbarcode::BARCODE_OUT_EPS
        Gbarcode.barcode_print(bc, eps_file, print_options)
        eps_file.fsync
      end
      convert_to_jpg barcode_eps_file_path, barcode_jpg_file_path, options[:resolution], options[:antialias]
      
      if block_given?
        File.open(barcode_jpg_file_path) do |jpg_file|
          yield jpg_file
        end
      end

      File.unlink barcode_eps_file_path

      if options[:keep_jpg]
        barcode_jpg_file_path
      else
        File.unlink barcode_jpg_file_path
      end
    end
    
    def barcode_jpg_file_path
      @barcode_jpg_file_path ||= "#{barcode_path_prefix}.jpg"
    end
    
    def barcode_eps_file_path
      @barcode_eps_file_path ||= "#{barcode_path_prefix}.eps"
    end
    
    private
    
    def barcode_path_prefix
      File.expand_path("#{self.class.name.underscore}-#{id}-barcode", "#{Rails.root}/tmp")
    end
    
    def convert_to_jpg(eps_path, jpg_path, resolution, antialias)
      options = [].tap do |array|
        array << "-density #{resolution}" if resolution.present?
        array << "+antialias" if antialias
      end.join(" ")
      cmd = "convert #{options} eps:#{eps_path} jpg:#{jpg_path}"
      logger.info "#{cmd}"
      out = `#{cmd} 2>&1`
      logger.warn "convert_to_jpg: '#{cmd}' output '#{out}'" unless 0 == $?.exitstatus
    end
  end
end
