module ActsAsBarCodeAssigner
  ALLOWED_BAR_CODE_ENCODING_FORMATS = %w{ 128 128B 128C 39 I25 }.map { |name| [name, Gbarcode.const_get("BARCODE_#{name}")] }

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
    base.class_eval do
      has_many :bar_codes, :as => :bar_codeable, :dependent => :destroy, :order => "position"
    end
  end

  module ClassMethods
    def allowed_bar_code_encoding_formats
      ALLOWED_BAR_CODE_ENCODING_FORMATS
    end
  end
  
  module InstanceMethods
    def import_bar_codes(io, delete_existing, allow_duplicates)
      @tx_rolled_back = false
      BarCode.transaction do
        if delete_existing
          #
          # Leave assigned codes in place to prevent re-allocation.
          #
          bar_codes.delete bar_codes.all(:conditions => { :assigned => false })
        end
      
        existing_bar_codes = Set.new(bar_codes.all(:select => "code").map(&:code))

        FasterCSV.new(io).each do |row|
          code = row.first
          if code.present? && (allow_duplicates || !existing_bar_codes.include?(code))
            raise "'#{code}' is not a valid code" unless valid_bar_code?(code)
            bar_codes.create! :code => code
            existing_bar_codes << code
          end
        end
        
        if respond_to?(:bar_codes_valid?, true) && !bar_codes_valid?
          @tx_rolled_back = true
          raise ActiveRecord::Rollback
        end
      end

      if @tx_rolled_back
        return false
      else
        return true
      end
    rescue FasterCSV::MalformedCSVError
      errors.add_to_base("Bar code csv file has invalid formatting")
      return false
    end

    def assign_bar_code
      self.class.transaction do
        if (record = bar_codes.find(:first, :conditions => { :assigned => false }, :lock => true))
          record.update_attributes! :assigned => true
          record.code
        else
          raise "#{self.inspect}#assign_bar_code: No unassigned barcodes found"
        end
      end
    end

    private

    def valid_bar_code?(code)
      true
    end
  end
end
