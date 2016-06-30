module BarCodes
	module Import

		def self.included(base)
			base.send :include, InstanceMethods
			base.class_eval do

				attr_accessor :bar_codes_csv
				attr_reader 	:delete_existing_unassigned_bar_codes, :allow_duplicate_bar_codes

				validate                :number_of_bar_codes_matches_quantity_times_voucher_multiple
				validates_inclusion_of  :bar_code_encoding_format, :in => allowed_bar_code_encoding_formats.map(&:second)

				before_validation :update_bar_codes, :unless => :new_record?
				after_create 			:update_bar_codes_after_create				
			end			
		end

		module InstanceMethods

			def bar_coded?
    		bar_codes.present?
  		end

		  def delete_existing_unassigned_bar_codes=(value)
		    @delete_existing_unassigned_bar_codes = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
		  end

		  def allow_duplicate_bar_codes=(value)
		    @allow_duplicate_bar_codes = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
		  end  		

		  def number_of_bar_codes_matches_quantity_times_voucher_multiple
		    if bar_codes.present? && bar_codes.count != (quantity * certificates_to_generate_per_unit_quantity)
		      errors.add_to_base "number of barcodes (#{bar_codes.count}) does not match quantity (#{quantity}) " +
		                         "multiplied by certificates_to_generate_per_unit_quantity (#{certificates_to_generate_per_unit_quantity})"
		    end
		  end

		  # if the deal is new we need to save the quantity instead of 
		  # expecting it to call save after the method call.
		  def update_bar_codes_after_create
		    q = self.quantity
		    update_bar_codes
		    save if q != self.quantity
		  end
		  
		  def update_bar_codes
		    if bar_codes_csv.present?
		      if import_bar_codes(bar_codes_csv, delete_existing_unassigned_bar_codes, allow_duplicate_bar_codes)
		        self.quantity = bar_codes.count / certificates_to_generate_per_unit_quantity
		      else
		        return false
		      end
		    elsif delete_existing_unassigned_bar_codes && bar_codes.unassigned.present?
		      bar_codes.unassigned.destroy_all
		      self.quantity = (count = (bar_codes.count / certificates_to_generate_per_unit_quantity)) > 0 ? count : nil
		    end
		    
		    return true
		  end		  

		  private
		  
		  def bar_codes_valid?
		    return true if bar_codes.blank?

		    if bar_codes.count.multiple_of?(certificates_to_generate_per_unit_quantity)
		      return true
		    else
		      errors.add_to_base("certificates_to_generate_per_unit_quantity (#{certificates_to_generate_per_unit_quantity}) " +
		                         "must divide evenly into the number of barcodes (#{bar_codes.count}), but does not")
		      return false
		    end
		  end		  

		end

	end
end
# testing123 - do not remove this line
