require File.dirname(__FILE__) + "/../../test_helper"

# hydra class DailyDealVariations::BarCodeTest

module DailyDealVariations

	class BarCodeTest < ActiveSupport::TestCase

		context "default bar code encoding format" do

			should "default to BARCODE_128B" do
				assert_equal Gbarcode::BARCODE_128B, DailyDealVariation.new.bar_code_encoding_format
			end

		end

		context "barcodes" do

			setup do
				@deal			 = Factory(:daily_deal)
				@deal.publisher.update_attribute(:enable_daily_deal_variations, true)
				@variation = Factory(:daily_deal_variation, :daily_deal => @deal)
			end

			should "have no bar_codes to begin with" do
				assert @variation.bar_codes.empty?
			end

			context "import bar codes" do

				setup do
					@variation.import_bar_codes StringIO.new("01234\n56789\n"), true, false
				end

				should "should have two barcodes" do
					assert_equal 2, @variation.bar_codes.size, "should have 2 barcodes"
					assert_equal %w{ 01234 56789 }, @variation.bar_codes.map(&:code)
			    assert_equal [false] * 2, @variation.bar_codes.map(&:assigned)
				end

				context "with two more codes" do

					should "add 2 new barcodes when delete existing is false" do
						@variation.import_bar_codes StringIO.new("abcde\nfghij\n"), false, false
						assert_equal 4, @variation.bar_codes.size, "should have 4 barcodes"
						assert_equal %w{ 01234 56789 abcde fghij }, @variation.bar_codes.map(&:code)
    				assert_equal [false] * 4, @variation.bar_codes.map(&:assigned)
					end

					should "replace existing barcodes when delete existing is true" do
						@variation.import_bar_codes StringIO.new("abcde\nfghij\n"), true, false
						assert_equal 2, @variation.bar_codes.size, "should have 2 barcodes"
				    assert_equal %w{ abcde fghij }, @variation.bar_codes.map(&:code)
				    assert_equal [false] * 2, @variation.bar_codes.map(&:assigned)
					end

				end

			end

			context "assign bar codes" do

				setup do
					@codes = %w{ 01234 56789 abcde fghij }
					@variation.import_bar_codes StringIO.new(@codes.join("\n") << "\n"), false, false					
				end

				should "be able to assign 4 codes" do
			    4.times do |i|
			      bar_code = @variation.assign_bar_code
			      assert_equal @codes[i], bar_code
			    end					
				end

				should "raise an error when trying to assign more than 4" do
					assert_raise RuntimeError do
						5.times do |i|
							@variation.assign_bar_code
						end
					end
				end

			end

			context "barcodes, deal quantity, and certificates_to_generate_per_unit_quantity" do

				context "when barcodes are uploaded, and certificates_to_generate_per_unit_quantity is 1" do

					setup do
						@variation.update_attributes(:quantity => 20, :certificates_to_generate_per_unit_quantity => 1)
						@variation.bar_codes_csv = StringIO.new(20.times.map { |i| "barcode#{i}" }.join("\n"))
					end

		      context "when the quantity is set to 10" do
		        
		        setup do
		          @variation.quantity = 10
		        end
		        
		        should "reset the quantity to 20 on validation and create the barcodes" do
		          assert_difference("BarCode.count", 20) { assert @variation.valid? }
		          assert_equal 20, @variation.quantity
		        end
		        
		      end					

		      context "when the certificates_to_generate_per_unit_quantity is 3" do
		        
		        setup do
		        	@variation.certificates_to_generate_per_unit_quantity = 3
		        end
		        
		        should "be invalid, because certificates_to_generate_per_unit_quantity does not divide evenly " +
		               "into the number of uploaded barcodes" do
		          assert_no_difference("BarCode.count") { assert @variation.invalid? }
		          assert_equal ["certificates_to_generate_per_unit_quantity (3) must divide evenly into the number of barcodes (20), but does not"],
		                       @variation.errors.full_messages
		        end
		        
		      end			

		      context "when the certificates_to_generate_per_unit_quantity is 2" do
	        
		        setup do
		          @variation.certificates_to_generate_per_unit_quantity = 2
		        end
		        
		        should "set the deal quantity to 10 on validation, and create the barcodes" do
		          assert_equal 20, @variation.quantity
		          assert_difference("BarCode.count", 20) { assert @variation.valid? }
		          assert_equal 10, @variation.quantity
		        end
	        
	      	end		      

				end

			end

		  context "barcode assignment to captured purchases with certificates_to_generate_per_unit_quantity > 1" do
		    
		    setup do
		    	@variation.update_attributes(:certificates_to_generate_per_unit_quantity => 2, :quantity => 20)
		      @variation.bar_codes_csv = StringIO.new(20.times.map { |i| "barcode#{i}" }.join("\n"))
		      @variation.save!
		      @purchase = Factory :captured_daily_deal_purchase, :daily_deal => @deal, :daily_deal_variation => @variation, :quantity => 3
		      @certificates = @purchase.daily_deal_certificates
		    end
		    
		    should "assign a barcode to each of the generated vouchers" do
		      assert_equal 6, @certificates.size
		      assert @certificates.all? { |c| c.bar_code.present? }
		    end
		    
		  end			

		end

	end

end