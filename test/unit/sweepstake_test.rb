require File.dirname(__FILE__) + "/../test_helper"

class SweepstakeTest < ActiveSupport::TestCase

  fast_context "validation" do
    
    should validate_presence_of :publisher
    should validate_presence_of :value_proposition
    should validate_presence_of :terms
    should validate_presence_of :official_rules
    
    fast_context "hide_at date" do
      
      setup do
        @publisher = Factory(:publisher)
      end
      
      fast_context "with no start at date" do
        
        should "not be valid" do
          sweepstake = @publisher.sweepstakes.build( Factory.attributes_for(:sweepstake, :start_at => nil, :hide_at => 3.days.from_now) )
          assert !sweepstake.valid?
        end
        
      end
      
      fast_context "with a start at date in the future" do
        
        should "not be valid" do
          sweepstake = @publisher.sweepstakes.build( Factory.attributes_for(:sweepstake, :start_at => 4.days.from_now, :hide_at => 3.days.from_now) )
          assert !sweepstake.valid?
        end
        
      end
      
      fast_context "with a start at date in the past" do
        
        should "be valid" do
          sweepstake = @publisher.sweepstakes.build( Factory.attributes_for(:sweepstake, :start_at => 2.days.ago, :hide_at => 3.days.from_now, :featured => false) )
          assert sweepstake.valid?
        end
        
      end
      
    end    
    
    fast_context "featured" do
      
      setup do
        @publisher = Factory(:publisher)
      end
      
      fast_context "with no other featured sweepstakes for publisher" do
        
        setup do
          @sweepstake = Factory(:sweepstake, :publisher => @publisher, :featured => true)
        end
        
        should "be a valid sweepstake" do
          assert @sweepstake.valid?
        end
        
        should "be a featured sweepstake" do
          assert @sweepstake.featured?
        end
        
      end
      
      fast_context "with an existing featured sweepstake" do
        
        setup do
          @existing_sweepstake = Factory( :sweepstake, :publisher => @publisher, :start_at => 1.day.ago, :hide_at => 1.day.from_now, :featured => true )
        end
        
        fast_context "with another active featured sweepstake" do
            
          setup do
            @sweepstake = @publisher.sweepstakes.build( Factory.attributes_for( :sweepstake, :publisher => @publisher, :start_at => 3.days.ago, :hide_at => Time.now, :featured => true ) )
          end

          should "not be a valid sweepstake" do
            assert !@sweepstake.valid?
          end
          
        end      

        fast_context "with another featured sweepstake in the future" do
          setup do
            @sweepstake = @publisher.sweepstakes.build Factory.attributes_for(:sweepstake, :publisher => @publisher, :featured => true, :start_at => 10.days.from_now, :hide_at => 11.days.from_now)
          end

          should "be a valid sweepstake" do
            assert @sweepstake.valid?
          end
        end

        fast_context "updating featured deal" do

          should "be a valid sweepstake" do
            @existing_sweepstake.update_attribute(:description, "dummy")
            assert @existing_sweepstake.valid?
          end

        end
        
      end
      
    end
      
    fast_context "of max_entries_period" do
      setup do
        @sweepstake = Factory.build(:sweepstake, 
                                    :unlimited_entries => false, 
                                    :max_entries_period => Sweepstake::ENTRY_PERIODS::Day,
                                    :max_entries_per_period => nil)
      end
      should "validate presence of max_entries_per_period when nil" do
        assert @sweepstake.invalid?, "Should not be valid "
        assert_equal "Max entries per period can't be blank", @sweepstake.errors.on(:max_entries_per_period)
      end
    end
    
    fast_context "of max_entries_period" do
      setup do
        @sweepstake = Factory.build(:sweepstake, 
                                    :unlimited_entries => false, 
                                    :max_entries_period => Sweepstake::ENTRY_PERIODS::Day,
                                    :max_entries_per_period => "")
      end
      should "validate presence of max_entries_per_period when blank" do
        assert @sweepstake.invalid?, "Should not be valid"
        assert_equal "Max entries per period can't be blank", @sweepstake.errors.on(:max_entries_per_period)
      end
    end
    
    fast_context "of max_entries_per_period" do
      setup do
        @sweepstake = Factory.build(:sweepstake, 
                                    :unlimited_entries => false, 
                                    :max_entries_period => Sweepstake::ENTRY_PERIODS::Day,
                                    :max_entries_per_period => nil)
      end
      should "validate presence of max_entries_period when nil" do
        assert @sweepstake.invalid?, "Should not be valid"
        assert_equal "Max entries per period can't be blank", @sweepstake.errors.on(:max_entries_per_period)
      end
    end
    
    fast_context "of max_entries_per_period" do
      setup do
        @sweepstake = Factory.build(:sweepstake, 
                                    :unlimited_entries => false, 
                                    :max_entries_period => Sweepstake::ENTRY_PERIODS::Day,
                                    :max_entries_per_period => "")
      end
      should "validate presence of max_entries_period when blank" do
        assert @sweepstake.invalid?, "Should not be valid"
        assert_equal "Max entries per period can't be blank", @sweepstake.errors.on(:max_entries_per_period)
      end
    end
    
    fast_context "of max_entries_per_period and max_entries_period when nil" do
      setup do
        @sweepstake = Factory.build(:sweepstake, 
                                    :unlimited_entries => true, 
                                    :max_entries_period => nil, 
                                    :max_entries_per_period => nil)
      end
      should "NOT validate presence of either when unlimited entries present" do
        assert @sweepstake.valid?, "Should be valid"
      end
    end
    
    fast_context "of max_entries_per_period and max_entries_period when blank" do
      setup do
        @sweepstake = Factory.build(:sweepstake, 
                                    :unlimited_entries => true, 
                                    :max_entries_period => "", 
                                    :max_entries_per_period => "")
      end
      should "NOT validate presence of either when unlimited entries present" do
        assert @sweepstake.valid?, "Should be valid"
      end

    end
  
  end
  
  fast_context "association" do
    
    should belong_to :publisher
    should have_many :entries
    
  end
  
  fast_context "callbacks" do
    
    context "when unlimited entries true" do
      setup do
        @sweepstake = Factory.build(:sweepstake, 
                                    :unlimited_entries => true, 
                                    :max_entries_per_period => 1, 
                                    :max_entries_period => Sweepstake::ENTRY_PERIODS::Day)
      end
      should "clear max_entries_period and max_entries_per_period before save" do
        assert_equal @sweepstake.max_entries_per_period, 1
        assert_equal @sweepstake.max_entries_period, Sweepstake::ENTRY_PERIODS::Day
        @sweepstake.save!
        assert_equal @sweepstake.reload.max_entries_per_period, nil
        assert_equal @sweepstake.max_entries_period, nil
      end
    end
    
    context "when unlimited entries true" do
      setup do
        @sweepstake = Factory.build(:sweepstake, 
                                    :unlimited_entries => false, 
                                    :max_entries_per_period => 1, 
                                    :max_entries_period => Sweepstake::ENTRY_PERIODS::Day)
      end
      should "NOT clear max_entries_period and max_entries_per_period before save" do
        assert_equal @sweepstake.max_entries_per_period, 1
        assert_equal @sweepstake.max_entries_period, Sweepstake::ENTRY_PERIODS::Day
        @sweepstake.save!
        assert_equal @sweepstake.max_entries_per_period, 1
        assert_equal @sweepstake.max_entries_period, Sweepstake::ENTRY_PERIODS::Day
      end
    end
    
  end
  
  fast_context "entries" do
    
    setup do
      @sweepstake = Factory(:sweepstake)
    end
  
    fast_context "with an invalid consumer" do
    
      setup do
        @consumer = Factory(:consumer)
        @consumer.email = ""
        @entry = @sweepstake.entries.create( :consumer => @consumer, :agree_to_terms => "1", :is_an_adult => "1", :phone_number => "1-206-927-3333" )
      end
      
      should "mark agree to terms to true" do
        assert @entry.agree_to_terms
      end
      
      should "mark is an adult to true" do
        assert @entry.is_an_adult
      end
      
      should "not be valid" do
        assert !@entry.valid?
      end
      
    end
    
    fast_context "with a valid consumer and agreeing to terms and is an adult" do
      
      setup do        
        @entry = @sweepstake.entries.create( :consumer => Factory(:consumer), :agree_to_terms => "1", :is_an_adult => "1", :phone_number => "1-206-927-3333" )        
      end
      
      should "be a valid entry" do
        assert @entry.valid?
      end
      
    end
    
  end

end
