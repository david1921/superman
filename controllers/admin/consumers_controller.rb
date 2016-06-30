module Admin
  class ConsumersController < ApplicationController
    if ssl_rails_environment?
      ssl_required :new, :create, :edit, :update
    end

    before_filter :load_consumer, :authorize_edit_update, :only => [:edit, :update]
    before_filter :admin_privilege_required, :except => [:edit, :update]
    before_filter :assign_publishers

    def new
      @consumer = Consumer.new
      render :edit
    end
    
    def create
      @consumer = Consumer.new(params[:consumer])
      if @consumer.save
        flash[:notice] = "Created #{@consumer.name}"
        redirect_to edit_admin_consumer_path(@consumer)
      else
        render :edit
      end
    end
    
    def edit; end

    def update
      if !params[:credit_to_add].blank? && full_admin?
       if params[:credit_to_add].to_f < 50 
         @consumer.credits << Credit.new(:amount => params[:credit_to_add].to_f, :origin => @consumer.publisher, :memo => "Added by #{current_user.login} ")
         flash[:notice] = "Added $#{params[:credit_to_add].to_f.to_s} of credit to #{@consumer.name}" if @consumer.save
       else
        flash[:error] = "Max credit allowed is $50"
       end
        redirect_to edit_admin_consumer_path(@consumer)
      else
        if @consumer.update_attributes(params[:consumer])
          flash[:notice] = "Updated #{@consumer.name}"
          redirect_to edit_admin_consumer_path(@consumer)
        else
          render :edit
        end
      end
      

    end
    
    def current_publisher
      @publisher
    end

    private
    
    def assign_publishers
      @publishers = Publisher.all
    end

    def authorize_edit_update
      current_user && current_user.can_manage_consumer?(@consumer) or access_denied
    end

    def load_consumer
      @consumer = Consumer.find(params[:id])
    end
  end
end
