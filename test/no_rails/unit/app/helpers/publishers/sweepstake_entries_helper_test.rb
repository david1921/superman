require File.dirname(__FILE__) + "/../../helpers_helper"

# hydra class Publishers::SweepstakeEntriesHelperTest

module Publishers
  class SweepstakeEntriesHelperTest < Test::Unit::TestCase

    def setup
      @obj = Object.new.extend SweepstakeEntriesHelper
    end

    context "#entries_path" do
      should "return publisher sweepstakes entries path for publisher label and sweepstake" do
        label = mock('label')
        @obj.instance_variable_set(:@publisher, mock('publisher', :label => label))
        sweepstake = mock('sweepstake')
        @obj.instance_variable_set(:@sweepstake, sweepstake)
        @obj.expects(:publisher_sweepstake_entries_path).with(label, sweepstake)
        @obj.entries_path
      end
    end
    
    context "third_party_opt_in_display_value" do
            
      should "return an empty string when Sweepstake#show_promotional_opt_in_checkbox is false" do
        sweepstake = stub 'sweepstake', :show_promotional_opt_in_checkbox? => false, :show_promotional_opt_in_checkbox? => false
        sweepstake_entry = stub 'sweepstake_entry', :receive_promotional_emails? => false, :sweepstake => sweepstake
        assert_equal "", @obj.third_party_opt_in_display_value(sweepstake_entry)
      end
      
      should "return 'Yes' when Sweepstake#show_promotional_opt_in_checkbox is true and " +
             "SweepstakeEntry#receive_promotional_emails is true" do
        sweepstake = stub 'sweepstake', :show_promotional_opt_in_checkbox? => true
        sweepstake_entry = stub 'sweepstake_entry', :receive_promotional_emails? => true, :sweepstake => sweepstake
        assert_equal "Yes", @obj.third_party_opt_in_display_value(sweepstake_entry)
      end
             
      should "return 'No' when Sweepstake#show_promotional_opt_in_checkbox is true and " +
             "SweepstakeEntry#receive_promotional_emails is false" do
        sweepstake = stub 'sweepstake', :show_promotional_opt_in_checkbox? => true
        sweepstake_entry = stub 'sweepstake_entry', :receive_promotional_emails? => false, :sweepstake => sweepstake
        assert_equal "No", @obj.third_party_opt_in_display_value(sweepstake_entry)
      end
      
    end

    context "#login_errors_object" do
      should "return nil when there's a current user'" do
        @obj.stubs(:current_consumer).returns(mock('consumer'))
        assert_nil @obj.login_errors_object
      end

      context "no current user" do
        setup do
          @obj.stubs(:current_consumer).returns(nil)
        end

        should "return nil unless both login and password were supplied" do
          @obj.stubs(:params).returns({:session => nil})
          assert_nil @obj.login_errors_object

          @obj.stubs(:params).returns({:session => {}})
          assert_nil @obj.login_errors_object

          @obj.stubs(:params).returns({:session => {:email => 'email', :password => nil}})
          assert_nil @obj.login_errors_object
        end

        should "return a new consumer with a base login failure error" do
          @obj.stubs(:params).returns({:session => {:email => 'email', :password => 'password'}})
          consumer = mock('consumer')
          @obj.stubs(:new_consumer).returns(consumer)
          errors = mock('errors')
          error = mock('error')
          @obj.stubs(:t).with('failed_login_message').returns(error)
          errors.expects(:add_to_base).with(error)
          consumer.stubs(:errors).returns(errors)
          @obj.login_errors_object
        end
      end
    end

  end
end