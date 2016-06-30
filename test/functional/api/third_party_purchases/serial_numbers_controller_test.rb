require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Api::ThirdPartyPurchases::SerialNumbersControllerTest

class Api::ThirdPartyPurchases::SerialNumbersControllerTest < ActiveSupport::TestCase
  should "inherit from Api::ThirdPartyPurchases::ApplicationController" do
    assert_equal Api::ThirdPartyPurchases::ApplicationController, Api::ThirdPartyPurchases::SerialNumbersController.superclass
  end

  context "all actions" do
    setup do
      @controller = Api::ThirdPartyPurchases::SerialNumbersController.new
    end

    context "#create" do
      setup do
        @xml_body = 'some xml content'
        request = mock('Request', :body => mock(:read => @xml_body))
        @controller.stubs(:request).returns(request)
        @user = mock('User')
        @controller.instance_variable_set(:@user, @user)
      end

      should "execute a serial number request and render a serial number response as xml" do
        snreq = mock('SerialNumberRequest')
        Api::ThirdPartyPurchases::SerialNumberRequest.expects(:new).with(:xml => @xml_body, :user => @user).returns(snreq)
        snreq.expects(:execute)
        xml = mock('xml response')
        snresp = mock(:to_xml => xml)
        Api::ThirdPartyPurchases::SerialNumberResponse.expects(:new).with(:request => snreq).returns(snresp)
        @controller.expects(:render).with(:text => xml)
        @controller.create
      end
    end
  end
end