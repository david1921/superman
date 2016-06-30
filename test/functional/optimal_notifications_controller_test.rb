require File.join(File.dirname(__FILE__), "..", "test_helper")

class OptimalNotificationsControllerTest < ActionController::TestCase
  
  context "#create" do
    
    context "with a successful purchase response" do
      
      setup do
        ActionMailer::Base.deliveries = []
        @daily_deal_purchase = Factory :pending_daily_deal_purchase, :uuid => "1f139847-dadf-460c-a12e-d4d5698a2f1e"
      end
      
      should "set the daily deal purchase payment status to captured" do
        assert_not_equal "captured", @daily_deal_purchase.payment_status
        post :create,
             :encodedMessage => "PHByb2ZpbGVDaGVja291dFJlc3BvbnNlIHhtbG5zPSJ3d3cub3B0aW1hbHBheW1lbnRzLmNvbS9j\naGVja291dCI+CiAgPGNvbmZpcm1hdGlvbk51bWJlcj4xMjg0MDU4MTI8L2NvbmZpcm1hdGlvbk51\nbWJlcj4KICA8bWVyY2hhbnRSZWZOdW0+MWYxMzk4NDctZGFkZi00NjBjLWExMmUtZDRkNTY5OGEy\nZjFlPC9tZXJjaGFudFJlZk51bT4KICA8Y3VzdG9tZXJFbWFpbD5icmFkYkAzMHNsZWVwcy5jb208\nL2N1c3RvbWVyRW1haWw+CiAgPGFjY291bnROdW0+ODk5OTcwMTU8L2FjY291bnROdW0+CiAgPGNh\ncmRUeXBlPlZJPC9jYXJkVHlwZT4KICA8ZGVjaXNpb24+QUNDRVBURUQ8L2RlY2lzaW9uPgogIDxj\nb2RlPjA8L2NvZGU+CiAgPGRlc2NyaXB0aW9uPk5vIEVycm9yPC9kZXNjcmlwdGlvbj4KICA8dHhu\nVGltZT4yMDExLTAzLTAyVDE3OjMxOjIxLjkxMS0wNTowMDwvdHhuVGltZT4KICA8cGF5bWVudE1l\ndGhvZD5DQzwvcGF5bWVudE1ldGhvZD4KICA8bGFzdEZvdXJEaWdpdHM+MDAwMjwvbGFzdEZvdXJE\naWdpdHM+CiAgPHBheW1lbnRNZXRob2RDb25maXJtYXRpb25OdW1iZXI+MTI4NDA1ODEyPC9wYXlt\nZW50TWV0aG9kQ29uZmlybWF0aW9uTnVtYmVyPgo8L3Byb2ZpbGVDaGVja291dFJlc3BvbnNlPg==",
             :signature => "VPpfSLrE8FU8F74U85ZyhdesYlY="
        @daily_deal_purchase.reload
        assert_equal "captured", @daily_deal_purchase.payment_status
      end
      
      should "create and send the deal voucher" do
        assert ActionMailer::Base.deliveries.blank?

        assert @daily_deal_purchase.daily_deal_certificates.blank?
        post :create,
             :encodedMessage => "PHByb2ZpbGVDaGVja291dFJlc3BvbnNlIHhtbG5zPSJ3d3cub3B0aW1hbHBheW1lbnRzLmNvbS9j\naGVja291dCI+CiAgPGNvbmZpcm1hdGlvbk51bWJlcj4xMjg0MDU4MTI8L2NvbmZpcm1hdGlvbk51\nbWJlcj4KICA8bWVyY2hhbnRSZWZOdW0+MWYxMzk4NDctZGFkZi00NjBjLWExMmUtZDRkNTY5OGEy\nZjFlPC9tZXJjaGFudFJlZk51bT4KICA8Y3VzdG9tZXJFbWFpbD5icmFkYkAzMHNsZWVwcy5jb208\nL2N1c3RvbWVyRW1haWw+CiAgPGFjY291bnROdW0+ODk5OTcwMTU8L2FjY291bnROdW0+CiAgPGNh\ncmRUeXBlPlZJPC9jYXJkVHlwZT4KICA8ZGVjaXNpb24+QUNDRVBURUQ8L2RlY2lzaW9uPgogIDxj\nb2RlPjA8L2NvZGU+CiAgPGRlc2NyaXB0aW9uPk5vIEVycm9yPC9kZXNjcmlwdGlvbj4KICA8dHhu\nVGltZT4yMDExLTAzLTAyVDE3OjMxOjIxLjkxMS0wNTowMDwvdHhuVGltZT4KICA8cGF5bWVudE1l\ndGhvZD5DQzwvcGF5bWVudE1ldGhvZD4KICA8bGFzdEZvdXJEaWdpdHM+MDAwMjwvbGFzdEZvdXJE\naWdpdHM+CiAgPHBheW1lbnRNZXRob2RDb25maXJtYXRpb25OdW1iZXI+MTI4NDA1ODEyPC9wYXlt\nZW50TWV0aG9kQ29uZmlybWF0aW9uTnVtYmVyPgo8L3Byb2ZpbGVDaGVja291dFJlc3BvbnNlPg==",
             :signature => "VPpfSLrE8FU8F74U85ZyhdesYlY="

        @daily_deal_purchase.reload
        assert_response 204
        assert_equal 1, @daily_deal_purchase.daily_deal_certificates.length
        assert_equal 1, ActionMailer::Base.deliveries.length
      end
      
    end
    
    context "with a failed purchase response" do

      setup do
        ActionMailer::Base.deliveries = []
        @daily_deal_purchase = Factory :pending_daily_deal_purchase, :uuid => "081f3358-34e8-4050-b644-1f6689617c6f"
      end

      should "set leave the daily deal purchase payment status as pending" do
        assert_equal "pending", @daily_deal_purchase.payment_status
        post :create,
             :encodedMessage => "PHByb2ZpbGVDaGVja291dFJlc3BvbnNlIHhtbG5zPSJ3d3cub3B0aW1hbHBheW1lbnRzLmNvbS9j\naGVja291dCI+CiAgPGNvbmZpcm1hdGlvbk51bWJlcj4xMjg0MDgwMzk8L2NvbmZpcm1hdGlvbk51\nbWJlcj4KICA8bWVyY2hhbnRSZWZOdW0+MDgxZjMzNTgtMzRlOC00MDUwLWI2NDQtMWY2Njg5NjE3\nYzZmPC9tZXJjaGFudFJlZk51bT4KICA8Y3VzdG9tZXJFbWFpbD5icmFkYkAzMHNsZWVwcy5jb208\nL2N1c3RvbWVyRW1haWw+CiAgPGFjY291bnROdW0+ODk5OTcwMTU8L2FjY291bnROdW0+CiAgPGNh\ncmRUeXBlPlZJPC9jYXJkVHlwZT4KICA8ZGVjaXNpb24+REVDTElORUQ8L2RlY2lzaW9uPgogIDxj\nb2RlPjMwMTU8L2NvZGU+CiAgPGFjdGlvbkNvZGU+RDwvYWN0aW9uQ29kZT4KICA8ZGVzY3JpcHRp\nb24+VGhlIGJhbmsgaGFzIHJlcXVlc3RlZCB0aGF0IHlvdSBwcm9jZXNzIHRoZSB0cmFuc2FjdGlv\nbiBtYW51YWxseSBieSBjYWxsaW5nIHRoZSBjYXJkaG9sZGVyJ3MgY3JlZGl0IGNhcmQgY29tcGFu\neS48L2Rlc2NyaXB0aW9uPgogIDx0eG5UaW1lPjIwMTEtMDMtMDNUMTc6MjA6NDYuMDkzLTA1OjAw\nPC90eG5UaW1lPgogIDxwYXltZW50TWV0aG9kPkNDPC9wYXltZW50TWV0aG9kPgogIDxsYXN0Rm91\nckRpZ2l0cz4wODIxPC9sYXN0Rm91ckRpZ2l0cz4KICA8cGF5bWVudE1ldGhvZENvbmZpcm1hdGlv\nbk51bWJlcj4xMjg0MDgwMzk8L3BheW1lbnRNZXRob2RDb25maXJtYXRpb25OdW1iZXI+CjwvcHJv\nZmlsZUNoZWNrb3V0UmVzcG9uc2U+",
             :signature => "dmtXhv6hvq9XErS3fee0gfvnuxA="
        @daily_deal_purchase.reload
        assert_equal "pending", @daily_deal_purchase.payment_status        
      end
      
      should "*not* create and send the deal voucher" do
        assert ActionMailer::Base.deliveries.blank?
        assert @daily_deal_purchase.daily_deal_certificates.blank?
        post :create,
             :encodedMessage => "PHByb2ZpbGVDaGVja291dFJlc3BvbnNlIHhtbG5zPSJ3d3cub3B0aW1hbHBheW1lbnRzLmNvbS9j\naGVja291dCI+CiAgPGNvbmZpcm1hdGlvbk51bWJlcj4xMjg0MDgwMzk8L2NvbmZpcm1hdGlvbk51\nbWJlcj4KICA8bWVyY2hhbnRSZWZOdW0+MDgxZjMzNTgtMzRlOC00MDUwLWI2NDQtMWY2Njg5NjE3\nYzZmPC9tZXJjaGFudFJlZk51bT4KICA8Y3VzdG9tZXJFbWFpbD5icmFkYkAzMHNsZWVwcy5jb208\nL2N1c3RvbWVyRW1haWw+CiAgPGFjY291bnROdW0+ODk5OTcwMTU8L2FjY291bnROdW0+CiAgPGNh\ncmRUeXBlPlZJPC9jYXJkVHlwZT4KICA8ZGVjaXNpb24+REVDTElORUQ8L2RlY2lzaW9uPgogIDxj\nb2RlPjMwMTU8L2NvZGU+CiAgPGFjdGlvbkNvZGU+RDwvYWN0aW9uQ29kZT4KICA8ZGVzY3JpcHRp\nb24+VGhlIGJhbmsgaGFzIHJlcXVlc3RlZCB0aGF0IHlvdSBwcm9jZXNzIHRoZSB0cmFuc2FjdGlv\nbiBtYW51YWxseSBieSBjYWxsaW5nIHRoZSBjYXJkaG9sZGVyJ3MgY3JlZGl0IGNhcmQgY29tcGFu\neS48L2Rlc2NyaXB0aW9uPgogIDx0eG5UaW1lPjIwMTEtMDMtMDNUMTc6MjA6NDYuMDkzLTA1OjAw\nPC90eG5UaW1lPgogIDxwYXltZW50TWV0aG9kPkNDPC9wYXltZW50TWV0aG9kPgogIDxsYXN0Rm91\nckRpZ2l0cz4wODIxPC9sYXN0Rm91ckRpZ2l0cz4KICA8cGF5bWVudE1ldGhvZENvbmZpcm1hdGlv\nbk51bWJlcj4xMjg0MDgwMzk8L3BheW1lbnRNZXRob2RDb25maXJtYXRpb25OdW1iZXI+CjwvcHJv\nZmlsZUNoZWNrb3V0UmVzcG9uc2U+",
             :signature => "dmtXhv6hvq9XErS3fee0gfvnuxA="

        @daily_deal_purchase.reload
        assert_response 204
        assert @daily_deal_purchase.daily_deal_certificates.blank?
        assert ActionMailer::Base.deliveries.blank?
      end
      
    end
    
  end
  
end