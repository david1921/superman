module Debug
  class ResqueExceptionalTestsController < ApplicationController

    class ExceptionRaisingJob
      @queue = :test
      def self.perform
        raise "This is a test exception through resqueue."
      end
    end

    before_filter :admin_privilege_required

    def create
      Resque.enqueue(ExceptionRaisingJob)
      flash[:notice] = "Exception raising job has been queued."
      render :new
    end

  end
end