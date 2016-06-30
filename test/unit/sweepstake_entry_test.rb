require File.dirname(__FILE__) + "/../test_helper"

class SweepstakeEntryTest < ActiveSupport::TestCase
  
  fast_context "validations" do
    
    setup do
      @sweepstake_entry = Factory(:sweepstake_entry)
    end
    
    should "not be valid with missing sweepstake" do
      @sweepstake_entry.sweepstake = nil
      assert !@sweepstake_entry.valid?
      assert @sweepstake_entry.errors.on(:sweepstake).present?
    end
    
    should "not be valid with missing consumer" do
      @sweepstake_entry.consumer = nil
      assert !@sweepstake_entry.valid?
      assert @sweepstake_entry.errors.on(:consumer).present?
    end
    
    should "only be valid with valid phone numbers" do
      Factory(:sweepstake_entry, :phone_number => "1-206-927-3333")
      Factory(:sweepstake_entry, :phone_number => "12062332323")
      Factory(:sweepstake_entry, :phone_number => "2133331234")
    end
    
    should "not be valid with invalid phone number" do
      assert_raise ActiveRecord::RecordInvalid do 
        Factory(:sweepstake_entry, :phone_number => "")
      end
      assert_raise ActiveRecord::RecordInvalid do 
        Factory(:sweepstake_entry, :phone_number => "blah")
      end
      assert_raise ActiveRecord::RecordInvalid do 
        Factory(:sweepstake_entry, :phone_number => "5555555")
      end
    end
    
    should "validate the consumer accepted the terms" do
      @sweepstake_entry.agree_to_terms = ""
      assert !@sweepstake_entry.valid?
      assert @sweepstake_entry.errors.on_base.present?
    end
    
    should "validate the consumer indicated that they are over 18" do
      @sweepstake_entry.is_an_adult = ""
      assert !@sweepstake_entry.valid?
      assert @sweepstake_entry.errors.on_base.present?
    end
  
  end
  
  fast_context "associations" do
  
    should belong_to :sweepstake
    should belong_to :consumer
    
  end
  
  context "named scopes" do
    
    setup do
      @consumer = Factory(:consumer)
      @sweepstake = Factory(:sweepstake, :unlimited_entries => true)
      @entry_1 = Factory(:sweepstake_entry, 
                         :sweepstake => @sweepstake, 
                         :consumer => @consumer, 
                         :phone_number => "1-206-927-3333",
                         :created_at => Time.zone.now - 1.minute)
      @entry_2 = Factory(:sweepstake_entry, 
                         :sweepstake => @sweepstake, 
                         :consumer => @consumer, 
                         :phone_number => "1-206-927-3333",
                         :created_at => Time.zone.now - 90.minutes)
      #different consumer
      @entry_3 = Factory(:sweepstake_entry, 
                         :sweepstake => @sweepstake, 
                         :consumer => Factory(:consumer), 
                         :phone_number => "1-206-927-3333",
                         :created_at => Time.zone.now - 2.minutes)
      #different sweepstake
      @other_sweepstake = Factory(:sweepstake)
      @entry_4 = Factory(:sweepstake_entry, 
                         :sweepstake => @other_sweepstake, 
                         :consumer => @consumer, 
                         :phone_number => "1-206-927-3333",
                         :created_at => Time.zone.now - 61.minutes)
    end
    
    context "for_consumer" do
      should "return entries for consumer" do
        entries = SweepstakeEntry.for_consumer(@consumer)
        assert_equal [@entry_1, @entry_2, @entry_4], entries, "Should find three entries"
      end
    end
    
    context "created_between" do
      should "return entries created within dates" do
        entries = SweepstakeEntry.created_between(Time.zone.now - 3.minutes, Time.zone.now)
        assert_equal [@entry_1, @entry_3], entries, "Should find two entries"
      end
    end
    
    context "for_sweepstake" do
      should "return entries for sweepstake" do
        entries = SweepstakeEntry.for_sweepstake(@other_sweepstake)
        assert_equal [@entry_4], entries, "Should find one entry"
      end
    end
    
  end
  
  context "consumer entry limits" do
    
    setup do
      @consumer = Factory(:consumer)
    end
    
    context "unlimited" do
      
      setup do
        @sweepstake = Factory(:sweepstake, :unlimited_entries => true)
        Factory(:sweepstake_entry, :sweepstake => @sweepstake, :consumer => @consumer, :phone_number => "1-206-927-3333")
        Factory(:sweepstake_entry, :sweepstake => @sweepstake, :consumer => @consumer, :phone_number => "1-206-927-3333")
      end
      
      should "should allow multiple entries" do
        @entry_allowed = Factory.build(:sweepstake_entry, 
                                       :sweepstake => @sweepstake, 
                                       :consumer => @consumer, 
                                       :phone_number => "1-206-927-3333")
        assert_equal true, @entry_allowed.valid?, "Should be valid, but had errors: " << @entry_allowed.errors.full_messages.join(", ")
      end
    end
    
    context "sweepstake" do
      setup do
        @sweepstake = Factory(:sweepstake, 
                              :unlimited_entries => false,
                              :max_entries_per_period => 3,
                              :max_entries_period => Sweepstake::ENTRY_PERIODS::Sweepstake)
        Factory(:sweepstake_entry,:sweepstake => @sweepstake, :consumer => @consumer, :phone_number => "1-206-927-1111")
        Factory(:sweepstake_entry, :sweepstake => @sweepstake, :consumer => @consumer, :phone_number => "1-206-927-2222")
        #same consumer different sweepstake
        Factory(:sweepstake_entry, :sweepstake => Factory(:sweepstake), :consumer => @consumer, :phone_number => "1-206-927-1111")
      end
      
      context "within limit" do
        should "allow entry" do
          Timecop.freeze(Time.zone.now) do
            @valid_entry = Factory.build(:sweepstake_entry, 
                                         :sweepstake => @sweepstake, 
                                         :consumer => @consumer, 
                                         :phone_number => "1-206-927-3333")
            assert_equal false, @valid_entry.exceeds_entry_limits?
            assert_equal true, @valid_entry.valid?, "Should be valid, but had errors: " << @valid_entry.errors.full_messages.join(", ")
          end
        end
      end
      
      context "beyond limit" do
        setup do
          @valid_entry = Factory(:sweepstake_entry, :sweepstake => @sweepstake, :consumer => @consumer, :phone_number => "1-206-927-4444")
        end
        should "NOT allow entry" do
          Timecop.freeze(Time.zone.now) do
            @invalid_entry = Factory.build(:sweepstake_entry, 
                                     :sweepstake => @sweepstake, 
                                     :consumer => @consumer, 
                                     :phone_number => "1-206-927-5555",
                                     :created_at => Time.zone.now)
            assert_equal true, @invalid_entry.exceeds_entry_limits?
            assert_equal true, @invalid_entry.invalid?, "Should be invalid"
            assert_equal "Only 3 entries allowed per sweepstake", @invalid_entry.errors.on(:base)
          end
        end
      end
    end
    
    context "hour" do
      setup do
        @entry_date_time = Time.zone.local(2010, 10, 4, 12, 34, 56)
        @sweepstake = Factory(:sweepstake, 
                              :unlimited_entries => false,
                              :max_entries_per_period => 3,
                              :max_entries_period => Sweepstake::ENTRY_PERIODS::Hour)
        setup_existing_entries(@sweepstake, 
                               @consumer, 
                               @entry_date_time, 
                               @entry_date_time - 3.minutes,
                               @entry_date_time - 27.minutes,
                               @entry_date_time - 90.minutes)
      end
      
      context "within limit" do
        should "allow entry" do
          Timecop.freeze(@entry_date_time) do
            @valid_entry = Factory.build(:sweepstake_entry, 
                                         :sweepstake => @sweepstake, 
                                         :consumer => @consumer, 
                                         :phone_number => "1-206-927-4444")
            assert_equal false, @valid_entry.exceeds_entry_limits?
            assert_equal true, @valid_entry.valid?, "Should be valid, but had errors: " << @valid_entry.errors.full_messages.join(", ")
          end
        end
      end
      
      context "beyond limit" do
        should "NOT allow entry" do
          Timecop.freeze(@entry_date_time) do
            @valid_entry = Factory(:sweepstake_entry, 
                                   :sweepstake => @sweepstake, 
                                   :consumer => @consumer, 
                                   :phone_number => "1-206-927-5555",
                                   :created_at => @entry_date_time - 1.seconds)
            @invalid_entry = Factory.build(:sweepstake_entry, 
                                     :sweepstake => @sweepstake, 
                                     :consumer => @consumer, 
                                     :phone_number => "1-206-927-5555",
                                     :created_at => @entry_date_time)
            assert_equal true, @invalid_entry.exceeds_entry_limits?
            assert_equal true, @invalid_entry.invalid?, "Should be invalid"
            assert_equal "Only 3 entries allowed per hour", @invalid_entry.errors.on(:base)
          end
        end
      end
      
    end
    
    context "day" do
      
      setup do
        @entry_date_time = Time.zone.local(2010, 10, 4, 3, 34, 56)
        @sweepstake = Factory(:sweepstake, 
                              :unlimited_entries => false,
                              :max_entries_per_period => 3,
                              :max_entries_period => Sweepstake::ENTRY_PERIODS::Day)
        setup_existing_entries(@sweepstake, 
                               @consumer, 
                               @entry_date_time, 
                               Time.zone.local(2010, 10, 4, 1, 43, 56), #inside period
                               Time.zone.local(2010, 10, 4, 2, 22, 56), #inside period
                               Time.zone.local(2010, 10, 3, 22, 55, 12)) #outside period
      end
      
      context "within limit" do
        should "allow entry" do
          Timecop.freeze(@entry_date_time) do
            @valid_entry = Factory.build(:sweepstake_entry, 
                                         :sweepstake => @sweepstake, 
                                         :consumer => @consumer,
                                         :phone_number => "1-206-927-4444")
            assert_equal false, @valid_entry.exceeds_entry_limits?
            assert_equal true, @valid_entry.valid?, "Should be valid, but had errors: " << @valid_entry.errors.full_messages.join(", ")
          end
        end
      end
      
      context "beyond limit" do
        should "NOT allow entry" do
          Timecop.freeze(@entry_date_time) do
            @valid_entry = Factory(:sweepstake_entry, 
                                         :sweepstake => @sweepstake, 
                                         :consumer => @consumer,
                                         :phone_number => "1-206-927-4444",
                                         :created_at => @entry_date_time - 1.second)
            @invalid_entry = Factory.build(:sweepstake_entry, 
                                           :sweepstake => @sweepstake, 
                                           :consumer => @consumer, 
                                           :phone_number => "1-206-927-5555")
            assert_equal true, @invalid_entry.exceeds_entry_limits?
            assert_equal true, @invalid_entry.invalid?, "Should be invalid"
            assert_equal "Only 3 entries allowed per day", @invalid_entry.errors.on(:base)
          end
        end
      end
      
    end
    
    context "month" do
     
      setup do
        @entry_date_time = Time.zone.local(2010, 10, 4, 3, 34, 56)
        @sweepstake = Factory(:sweepstake, 
                              :unlimited_entries => false,
                              :max_entries_per_period => 3,
                              :max_entries_period => Sweepstake::ENTRY_PERIODS::Month)
        setup_existing_entries(@sweepstake, 
                               @consumer, 
                               @entry_date_time, 
                               Time.zone.local(2010, 10, 1, 5, 10, 43), #within period
                               Time.zone.local(2010, 10, 2, 18, 22, 13), #within period
                               Time.zone.local(2010, 9, 30, 12, 43, 2)) #outside period
      end
      
      context "within limit" do
        should "allow entry" do
          Timecop.freeze(@entry_date_time) do
            @valid_entry = Factory.build(:sweepstake_entry, 
                                         :sweepstake => @sweepstake, 
                                         :consumer => @consumer,
                                         :phone_number => "1-206-927-4444")
            assert_equal false, @valid_entry.exceeds_entry_limits?
            assert_equal true, @valid_entry.valid?, "Should be valid, but had errors: " << @valid_entry.errors.full_messages.join(", ")
          end
        end
      end
      
      context "beyond limit" do
        should "NOT allow entry" do
          Timecop.freeze(@entry_date_time) do
            @valid_entry = Factory(:sweepstake_entry, 
                                   :sweepstake => @sweepstake, 
                                   :consumer => @consumer, 
                                   :phone_number => "1-206-927-4444",
                                   :created_at => @entry_date_time - 1.seconds)
            @invalid_entry = Factory.build(:sweepstake_entry, 
                                     :sweepstake => @sweepstake, 
                                     :consumer => @consumer, 
                                     :phone_number => "1-206-927-5555")
            assert_equal true, @invalid_entry.exceeds_entry_limits?
            assert_equal true, @invalid_entry.invalid?, "Should be invalid"
            assert_equal "Only 3 entries allowed per month", @invalid_entry.errors.on(:base)
          end
        end
      end
     
    end
    
    context "week" do
      setup do
        @entry_date_time = Time.zone.local(2010, 11, 2, 12, 34, 56)
        @sweepstake = Factory(:sweepstake, 
                              :unlimited_entries => false,
                              :max_entries_per_period => 3,
                              :max_entries_period => Sweepstake::ENTRY_PERIODS::Week)
        setup_existing_entries(@sweepstake, 
                               @consumer, 
                               @entry_date_time, 
                               Time.zone.local(2010, 11, 1, 18, 32, 43), 
                               Time.zone.local(2010, 11, 1, 1, 12, 54), 
                               Time.zone.local(2010, 10, 31, 23, 1, 5))
      end
      
      context "within limit" do
        should "allow entry" do
          Timecop.freeze(@entry_date_time) do
            @valid_entry = Factory.build(:sweepstake_entry, 
                                         :sweepstake => @sweepstake, 
                                         :consumer => @consumer,
                                         :phone_number => "1-206-927-4444")
            assert_equal false, @valid_entry.exceeds_entry_limits?
            assert_equal true, @valid_entry.valid?, "Should be valid, but had errors: " << @valid_entry.errors.full_messages.join(", ")
          end
        end
      end
      
      context "beyond limit" do
        should "NOT allow entry" do
          Timecop.freeze(@entry_date_time) do
            @valid_entry = Factory(:sweepstake_entry, 
                                   :sweepstake => @sweepstake, 
                                   :consumer => @consumer, 
                                   :phone_number => "1-206-927-4444",
                                   :created_at => @entry_date_time - 1.seconds)
            @invalid_entry = Factory.build(:sweepstake_entry, 
                                     :sweepstake => @sweepstake, 
                                     :consumer => @consumer, 
                                     :phone_number => "1-206-927-5555")
            assert_equal true, @invalid_entry.exceeds_entry_limits?
            assert_equal true, @invalid_entry.invalid?, "Should be invalid"
            assert_equal "Only 3 entries allowed per week", @invalid_entry.errors.on(:base)
          end
        end
      end
    end
    
  end
  
  private 
  
  def setup_existing_entries(sweepstake, consumer, entry_date_time, entry_1_created_at, entry_2_created_at, entry_outside_period_created_at)
    #within max entries period
    Factory(:sweepstake_entry, 
            :sweepstake => sweepstake, 
            :consumer => consumer, 
            :phone_number => "1-206-927-1111", 
            :created_at => entry_1_created_at)
    Factory(:sweepstake_entry, 
            :sweepstake => sweepstake, 
            :consumer => consumer, 
            :phone_number => "1-206-927-2222", 
            :created_at => entry_2_created_at)
    #outside max entries period
    Factory(:sweepstake_entry,
            :sweepstake => sweepstake, 
            :consumer => consumer, 
            :phone_number => "1-206-927-3333", 
            :created_at => entry_outside_period_created_at)
    #same consumer different sweepstake
    Factory(:sweepstake_entry, 
            :sweepstake => Factory(:sweepstake), 
            :consumer => @consumer, 
            :phone_number => "1-206-927-6666", 
            :created_at => entry_1_created_at)
  end

end
