require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Publishers::PushNotificationsTest
module Publishers
  class PushNotificationsTest < ActiveSupport::TestCase
    
    context "daily deal push notifications" do
      
      setup do
        @publisher = Factory(:publisher)
      end
      
      context "daily_deals_requiring_notifications" do
        
        context "with no daily deals" do
          
          setup do
            @publisher.daily_deals.destroy_all
          end
          
          should "return empty array" do
            assert @publisher.daily_deals_requiring_notifications.empty?
          end
          
        end
        
        context "with a daily deal with no push_notifications_sent_at set" do
          
          setup do
            @advertiser = Factory(:advertiser, :publisher => @publisher)
            @daily_deal = Factory(:daily_deal, :advertiser => @advertiser)
          end
          
          
          context "with an active deal started less than 24 hours ago" do

            setup do
              @daily_deal.update_attributes(:start_at => 23.hours.ago, :hide_at => 2.days.from_now)
            end

            should "return daily deal" do
              assert @publisher.daily_deals_requiring_notifications.include?( @daily_deal )
            end
            
          end
          
          context "with an active deal started more than 24 hours ago" do

            setup do
              @daily_deal.update_attributes(:start_at => 25.hours.ago, :hide_at => 2.days.from_now)
            end

            should "NOT return daily deal" do
              assert !@publisher.daily_deals_requiring_notifications.include?( @daily_deal )
            end            
            
          end
          
        end
        
        context "with a daily deal with a push notification sent at set" do
          
          setup do
            @advertiser = Factory(:advertiser, :publisher => @publisher)
            @daily_deal = Factory(:daily_deal, :advertiser => @advertiser, :push_notifications_sent_at => 2.minutes.ago)
          end
          
          context "with an active deal" do
            
            setup do
              @daily_deal.update_attributes(:start_at => 23.hours.ago, :hide_at => 2.days.from_now)
            end

            should "NOT return daily deal" do
              assert !@publisher.daily_deals_requiring_notifications.include?( @daily_deal )
            end
            
          end
          
          context "with an active deal started more than 24 hours ago" do

            setup do
              @daily_deal.update_attributes(:start_at => 25.hours.ago, :hide_at => 2.days.from_now)
            end

            should "NOT return daily deal" do
              assert !@publisher.daily_deals_requiring_notifications.include?( @daily_deal )
            end            
            
          end
          
        end
        
      end
      
      context "send_push_notifications!" do
        
        context "with no push notification devices" do
          
          should "have not push notification devices" do
            assert @publisher.push_notification_devices.empty?
          end
          
          should "return false" do
            assert !@publisher.send_push_notifications!
          end
          
        end
        
        context "with push notification devices" do
          
          setup do
            @push_device_1 = Factory(:push_notification_device)
            @push_device_2 = Factory(:push_notification_device)
            @push_device_3 = Factory(:push_notification_device)
          end
          
          context "with no daily deals" do

            setup do
              @publisher.daily_deals.destroy_all
            end

            should "return false" do
              assert !@publisher.send_push_notifications!
            end

          end
          
          context "with an active daily deal" do
            
            setup do
              @advertiser = Factory(:advertiser, :publisher => @publisher)
              @daily_deal = Factory(:daily_deal, :advertiser => @advertiser, :start_at => 2.hours.ago, :hide_at => 3.days.from_now)
            end
            
            context "with no device options" do
              
              setup do
                @publisher.expects(:push_notification_devices).at_least_once.returns([@push_device_1, @push_device_2, @push_device_3])
              end
              
              should "send push notifications to each push device" do
                @push_device_1.expects(:send_notification!).with(@daily_deal.value_proposition)
                @push_device_2.expects(:send_notification!).with(@daily_deal.value_proposition)
                @push_device_3.expects(:send_notification!).with(@daily_deal.value_proposition)
                @publisher.send_push_notifications!          
                assert_not_nil @daily_deal.reload.push_notifications_sent_at, "should set push_notifications_sent_at"
              end
              
            end
            
            context "with device options" do
              
              setup do
                @devices = [@push_device_2.token, @push_device_3.token]
                push_notification_devices = mock("push_notification_devices")
                push_notification_devices.expects(:by_tokens).with(@devices).returns([@push_device_2, @push_device_3])
                push_notification_devices.expects(:empty?).returns(false)
                @publisher.expects(:push_notification_devices).at_least_once.returns(push_notification_devices)
              end
              
              should "send push notfications to device 2 and 3 only" do
                @push_device_1.expects(:send_notification!).never
                @push_device_2.expects(:send_notification!).with(@daily_deal.value_proposition)
                @push_device_3.expects(:send_notification!).with(@daily_deal.value_proposition)
                @publisher.send_push_notifications!(:devices => @devices)               
                assert_not_nil @daily_deal.reload.push_notifications_sent_at, "should set push_notifications_sent_at"
              end
              
            end
            
            
          end
          

          
        end
        
        
      end
      
      context "with_pem_file" do
        
        setup do
          @freedom = Factory :publishing_group, :label => "freedom"
          @ocregister = Factory :publisher, :label => "ocregister", :publishing_group => @freedom
          @zingindealz = Factory :publisher, :label => "zingindealz"
          @other_publisher = Factory :publisher
          
          @freedom_deal = Factory :daily_deal, :start_at => 5.hours.ago, :publisher => @ocregister
          @zingin_deal = Factory :daily_deal, :start_at => 5.hours.ago, :publisher => @zingindealz
          @other_deal = Factory :daily_deal, :start_at => 5.hours.ago, :publisher => @other_publisher
          
          @freedom_push_notification_device = Factory :push_notification_device, :publisher => @ocregister
          @zingin_push_notification_device = Factory :push_notification_device, :publisher => @zingindealz
          @other_push_notification_device = Factory :push_notification_device, :publisher => @other_publisher
          
          @ocregister.stubs(:push_notification_devices).returns([@freedom_push_notification_device])
          @zingindealz.stubs(:push_notification_devices).returns([@zingin_push_notification_device])
          @other_publisher.stubs(:push_notification_devices).returns([@other_push_notification_device])
        end
        
        should "be called with the publishing group label when a publisher-specific pem file does not exist" do
          @freedom_push_notification_device.expects(:with_pem_file).with(Rails.root.join("config/apns/freedom.pem"))
          @ocregister.send_push_notifications!
        end
        
        should "be called with the publisher label when the publisher-specific pem file does exist" do
          @zingin_push_notification_device.expects(:with_pem_file).with(Rails.root.join("config/apns/zingindealz.pem"))
          @zingindealz.send_push_notifications!
        end
        
        should "not be called when no pem file matching the publisher/pub group is found" do
          @other_push_notification_device.expects(:with_pem_file).never
          assert_raises(RuntimeError) { @other_publisher.send_push_notifications! }
        end
        
      end
      
    end

  end
end
