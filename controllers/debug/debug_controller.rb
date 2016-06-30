module Debug
  class DebugController < ApplicationController

    if ssl_rails_environment?
      ssl_required :request_info_ssl
    end

    before_filter :admin_privilege_required, :except => [:push_notifications, :version]
    before_filter :basic_auth, :only => :push_notifications

    def request_info
      @headers = request.headers
      @remote_ip = request.remote_ip
    end

    def request_info_ssl
      @headers = request.headers
      @remote_ip = request.remote_ip
      render :template => "debug/request_info"
    end

    def exceptional_test
      raise "Exceptional Test"
    end

    def push_notifications
      if request.post?
        DailyDealApi.send_push_notifications!
        flash.now[:notice] = "Push notification test sent"
      end

      render :layout => false
    end

    def version
      render :text => RAILS_ROOT.split("/").last
    end

    def time_zone
      render :text => "Time.zone is #{Time.zone}"
    end

    private

    def basic_auth
      authenticate_or_request_with_http_basic do |id, password|
        id == "debug" && password == "analog123"
      end
    end

  end
end
