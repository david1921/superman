require File.dirname(__FILE__) + "/../../test_helper"

class PublishersController::HttpsHostsTest < ActionController::TestCase
  
  tests PublishersController
  
  def setup
    @full_admin = Factory :admin
    @restricted_admin = Factory :restricted_admin
  end
  
  context "GET to :index" do
    
    context "as a full admin" do
      
      setup do
        login_as @full_admin
        get :index
        assert_response :success
      end
      
      should "show the link to manage https hosts" do
        assert_select "a", :text => "Configure HTTPS Hosts..."
      end
      
    end
    
    context "as a restricted admin" do
      
      setup do
        login_as @restricted_admin
        get :index
        assert_response :success
      end
      
      should "not show the link to manage https hosts" do
        assert_select "a", :text => "Configure HTTPS Hosts...", :count => 0
      end
      
    end
    
  end
  
  context "GET to :https_hosts" do
    
    should "render successfully for a full admin" do
      login_as @full_admin
      get :https_hosts
      assert_response :success
    end
    
    should "redirect to the login screen with an unauthorized access message for restricted admins" do
      login_as @restricted_admin
      get :https_hosts
      assert_redirected_to root_path
      assert_equal "Unauthorized access", flash[:notice]
    end
    
  end
  
  context "GET to :https_hosts with full admin user" do
    
    setup do
      login_as @full_admin
    end
    
    should "show a https_only_host[host] field" do
      get :https_hosts
      assert_select "input[name='https_only_host[host]']"
    end
    
    context "when no HTTPS hosts currently configured" do
      
      setup do
        HttpsOnlyHost.delete_all
        get :https_hosts
      end
      
      should "display a message saying there are no hosts requiring HTTPS" do
        assert_match /No hosts configured/, @response.body
      end
      
    end
    
    context "when HTTPS hosts are configured" do
      
      setup do
        Factory :https_only_host, :host => "secure.test.host"
        Factory :https_only_host, :host => "secure2.test.host"
        get :https_hosts
      end
      
      should "set the @https_hosts instance variable" do
        assert_equal %w(secure.test.host secure2.test.host), assigns(:https_hosts)
      end
      
      should "list the hosts" do
        assert_select "ul.https-hosts li span.host", :text => "secure.test.host"
        assert_select "ul.https-hosts li span.host", :text => "secure2.test.host"
      end
      
      should "include a delete link for each host" do
        assert_select "a[href='#{https_hosts_publishers_path(:https_only_host => { :host => "secure.test.host" })}']"
        assert_select "a[href='#{https_hosts_publishers_path(:https_only_host => { :host => "secure2.test.host" })}']"
      end
            
    end
    
  end
  
  context "DELETE to :https_hosts with a host name with full admin user" do
    
    setup do
      Factory :https_only_host, :host => "example.com"
      Factory :https_only_host, :host => "deleteme.example.com"
      login_as @full_admin
    end
    
    should "delete the host from the https_only_hosts table" do
      assert HttpsOnlyHost.exists?(:host => "deleteme.example.com")
      assert_difference "HttpsOnlyHost.count", -1 do
        delete :https_hosts, :https_only_host => { :host => "deleteme.example.com" }
      end
      assert !HttpsOnlyHost.exists?(:host => "deleteme.example.com")
      assert_equal "Removed HTTPS requirement for host deleteme.example.com", flash[:notice]
    end

  end
  
    
  context "POST to :https_hosts with a host name with full admin user" do
    
    setup do
      login_as @full_admin
    end
    
    should "add the host to the https_only_hosts table" do
      assert !HttpsOnlyHost.exists?(:host => "addme.example.com")
      assert_difference "HttpsOnlyHost.count", 1 do
        post :https_hosts, :https_only_host  => { :host => "addme.example.com" }
      end
      assert HttpsOnlyHost.exists?(:host => "addme.example.com")
      assert_equal "Successfully added HTTPS required for all pages served by addme.example.com", flash[:notice]
    end
    
  end
  
end