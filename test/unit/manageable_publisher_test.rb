require File.dirname(__FILE__) + "/../test_helper"

class ManageablePublisherTest < ActiveSupport::TestCase
  
  def setup
    @publishing_group = Factory :publishing_group, :name => "Some Pub Group", :label => "pubgroup", :self_serve => true
    @publisher_1 = Factory :publisher, :label => "pub-one", :publishing_group => @publishing_group
    @publisher_2 = Factory :publisher, :label => "pub-two", :publishing_group => @publishing_group
    @publisher_3 = Factory :publisher, :label => "pub-three", :publishing_group => @publishing_group
    @publisher_4 = Factory :publisher, :label => "pub-four"
  end
  
  context "ManageablePublisher" do
    
    should "be invalid when created with a user whose company type is Advertiser" do
      advertiser_user = Factory :user, :company => Factory(:advertiser)
      mp = Factory.build(:manageable_publisher, :user => advertiser_user, :publisher => @publisher_1)
      assert mp.invalid?
      assert_equal "User must have company_type PublishingGroup, but company_type is Advertiser", mp.errors.on(:user)
    end
    
    should "be invalid when created with an admin user" do
      admin = Factory :admin, :company => @publishing_group
      mp = Factory.build(:manageable_publisher, :user => admin, :publisher => @publisher_1)
      assert mp.invalid?
      assert_equal "User must not be an admin", mp.errors.on(:user)
    end
    
    should "be invalid when created with a user whose company type is Publisher" do
      publisher_user = Factory :user, :company => Factory(:publisher)
      mp = Factory.build(:manageable_publisher, :user => publisher_user, :publisher => @publisher_1)
      assert mp.invalid?
      assert_equal "User must have company_type PublishingGroup, but company_type is Publisher", mp.errors.on(:user)
    end
    
    should "be invalid when created with a user whose company type is PublishingGroup, " +
           "but the specified publisher_id belongs to a different PublishingGroup" do
      pg_user = Factory :user, :company => @publishing_group
      mp = Factory.build(:manageable_publisher, :user => pg_user, :publisher => @publisher_4)
      assert mp.invalid?
      assert_equal "Publisher must belong to publishing group 'Some Pub Group' (ID: #{@publishing_group.id}), but it does not", mp.errors.on(:publisher_id)
    end
           
    should "be valid when created with a User whose company type is PublishingGroup " +
           "and the specified publisher_id belongs to that PublishingGroup" do
      pg_user = Factory :user, :company => @publishing_group
      mp = Factory.build(:manageable_publisher, :user => pg_user, :publisher => @publisher_2)
      assert mp.valid?
    end
    
  end
  
  context "Publisher.manageable_by, called with a user whose company_type is PublishingGroup" do
    
    setup do
      @user = Factory :user, :company => @publishing_group
    end
    
    should "return all publishers in the publishing group, when the user has no restrictions " +
           "on which pubs they can manage (i.e. User#managable_publishers is empty)" do
      assert @user.manageable_publishers.blank?
      publishers = Publisher.manageable_by(@user)
      assert_equal 3, publishers.size
      assert_equal ["pub-one", "pub-three", "pub-two"], publishers.map(&:label).sort
    end
    
    should "return only the publishers the user can manage in the pub group" do
      Factory :manageable_publisher, :publisher => @publisher_2, :user => @user
      @user.reload
      publishers = Publisher.manageable_by(@user)
      assert_equal 1, publishers.size
      assert_equal "pub-two", publishers.first.label
    end
    
  end
  
  context "Advertiser.manageable_by, called with a user whose company_type is PublishingGroup" do
    
    setup do
      @user = Factory :user, :company => @publishing_group
      @pub_1_advertiser = Factory :advertiser, :publisher => @publisher_1
      @pub_2_advertiser = Factory :advertiser, :publisher => @publisher_2
      @pub_3_advertiser = Factory :advertiser, :publisher => @publisher_3
      @pub_4_advertiser = Factory :advertiser, :publisher => @publisher_4
    end
    
    should "include all advertisers in the user's publishing group, when user.manageable_publishers is blank" do
      assert @user.manageable_publishers.blank?
      assert_equal [@pub_1_advertiser.id, @pub_2_advertiser.id, @pub_3_advertiser.id], Advertiser.manageable_by(@user).map(&:id).sort
    end
    
    should "include only advertisers belonging to users.manageable_publishers, when .manageable_publishers is not blank" do
      Factory :manageable_publisher, :user => @user, :publisher => @publisher_2
      @user.reload
      assert_equal [@pub_2_advertiser.id], Advertiser.manageable_by(@user).map(&:id).sort
    end
    
  end
  
  context "Publisher.observable_by" do
    
    setup do
      @user = Factory :user, :company => @publishing_group
    end
    
    should "include all publishers in a user's pub group when user.manageable_publishers is blank" do
      assert_equal [@publisher_1.id, @publisher_2.id, @publisher_3.id], Publisher.observable_by(@user).map(&:id)
    end
    
    should "include only user.manageable_publishers, when .manageable_publishers is present" do
      Factory :manageable_publisher, :publisher => @publisher_3, :user => @user
      @user.reload
      assert_equal [@publisher_3.id], Publisher.observable_by(@user).map(&:id)
    end
    
  end
  
  context "Advertiser.observable_by" do

    setup do
      @user = Factory :user, :company => @publishing_group
      @pub_1_advertiser = Factory :advertiser, :publisher => @publisher_1
      @pub_2_advertiser = Factory :advertiser, :publisher => @publisher_2
      @pub_3_advertiser = Factory :advertiser, :publisher => @publisher_3
      @pub_4_advertiser = Factory :advertiser, :publisher => @publisher_4
    end
    
    should "include all advertisers in a user's pub group when user.manageable_publishers is blank" do
      assert_equal [@pub_1_advertiser.id, @pub_2_advertiser.id, @pub_3_advertiser.id], Advertiser.observable_by(@user).map(&:id).sort
    end
    
    should "include only advertisers belonging to the user.manageable_publishers, when present" do
      Factory :manageable_publisher, :publisher => @publisher_3, :user => @user
      @user.reload
      assert_equal [@pub_3_advertiser.id], Advertiser.observable_by(@user).map(&:id)
    end

    
  end
  
end