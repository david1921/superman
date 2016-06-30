module AuthorizationTestHelper
  def with_self_serve_publishing_group_user_required(publisher, check, &block)
    assign_fixtures(publisher)
    
    assert_user_required(&block)
    
    publisher.publishing_group.update_attributes :self_serve => false
    publisher.update_attributes! :self_serve => false
    [@admin].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@own_group, @other_group, @own_publisher, @other_publisher, @own_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end

    publisher.publishing_group.update_attributes :self_serve => true
    [@admin, @own_group].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@other_group, @own_publisher, @other_publisher, @own_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end

    publisher.update_attributes! :self_serve => true
    [@admin, @own_group].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@other_group, @own_publisher, @other_publisher, @own_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end
  end

  def with_login_managing_publisher_required(publisher, check, &block)
    assign_fixtures(publisher)
    
    assert_user_required(&block)
    
    publisher.publishing_group.update_attributes :self_serve => false
    publisher.update_attributes! :self_serve => false
    [@admin].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@own_group, @other_group, @own_publisher, @other_publisher, @own_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end
    
    publisher.publishing_group.update_attributes :self_serve => true
    [@admin, @own_group].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@other_group, @own_publisher, @other_publisher, @own_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end
    
    publisher.update_attributes! :self_serve => true
    [@admin, @own_group, @own_publisher].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@other_group, @other_publisher, @own_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end
  end
  
  def with_login_managing_advertiser_required(advertiser, check, &block)
    publisher = advertiser.publisher
    assign_fixtures(publisher, advertiser)
    
    assert_user_required(&block)
    
    publisher.publishing_group.update_attributes :self_serve => false
    publisher.update_attributes! :self_serve => false, :advertiser_self_serve => false
    [@admin].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@own_group, @other_group, @own_publisher, @other_publisher, @same_advertiser, @peer_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end

    publisher.publishing_group.update_attributes :self_serve => true
    [@admin, @own_group].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@other_group, @own_publisher, @other_publisher, @same_advertiser, @peer_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end
    
    publisher.reload  # need this to avoid StaleObject errors in tests
    publisher.update_attributes! :self_serve => true
    [@admin, @own_group, @own_publisher].each do |f|
      f.assert_access_allowed(check, &block)
    end
    [@other_group, @other_publisher, @same_advertiser, @peer_advertiser, @other_advertiser].each do |f|
      f.assert_raises_not_found(&block)
    end

    publisher.reload  # need this to avoid StaleObject errors in tests
    publisher.update_attributes! :advertiser_self_serve => true
    [@same_advertiser].each do |f|
      f.assert_access_allowed check, &block
    end
  end

  def prepare(user)
    @controller = nil
    setup_controller_request_and_response
    @request.session[:user_id] = user.try(:id)
  end
  
  private

  class Fixture
    def initialize(test, role, &block)
      @test = test
      @role = role
      @user = users.detect(&block)
      @test.assert_not_nil @user, "Should have a user fixture for #{role}"
    end
    
    def assert_raises_not_found
      @test.prepare(@user)
      @test.assert_raises ActiveRecord::RecordNotFound, "Should raise exception as #{@role}" do
        yield
      end
    end

    def assert_access_allowed(check)
      @test.prepare(@user)
      yield
      check.call @role
    end
    
    private
    
    def users
      @users ||= User.all
    end
  end
  
  def assign_fixtures(publisher, advertiser=nil)
    group = publisher.publishing_group
    assert_not_nil group, "Publisher fixture should belong to a publishing group"

    @admin = Fixture.new(self, "admin") { |user|
      user.has_admin_privilege?
    }
    @own_group = Fixture.new(self, "own group") { |user|
      group == user.company
    }
    @other_group = Fixture.new(self, "other group") { |user|
      user.company.is_a?(PublishingGroup) && group != user.company
    }
    @own_publisher = Fixture.new(self, "own publisher") { |user|
      publisher == user.company
    }
    @other_publisher = Fixture.new(self, "other publisher") { |user|
      user.company.is_a?(Publisher) && publisher != user.company
    }
    if advertiser
      @same_advertiser = Fixture.new(self, "same advertiser") { |user|
        advertiser == user.company
      }
      @peer_advertiser = Fixture.new(self, "peer advertiser") { |user|
        user.company.is_a?(Advertiser) && advertiser != user.company && publisher == user.company.publisher
      }
    else
      @own_advertiser = Fixture.new(self, "own advertiser") { |user|
        user.company.is_a?(Advertiser) && publisher == user.company.publisher
      }
    end
    @other_advertiser = Fixture.new(self, "other advertiser") { |user|
      user.company.is_a?(Advertiser) && publisher != user.company.publisher
    }
  end

  def assert_user_required(options={})
    prepare(nil)
    yield
    if options[:format] == :xml
      assert_response :unauthorized, "Should attempt HTTP authentication"
    else
      assert_redirected_to new_session_path, "Login should be required"
    end
  end
end
