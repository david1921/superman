class SubscribersController < ApplicationController
  include Publishers::Themes
 
  before_filter :admin_privilege_required, :only => [:upload]
  
  protect_from_forgery :except => [:new, :create]
 
  ssl_allowed :create
  
  layout nil
  
  def upload
    @publisher = Publisher.find(params[:publisher_id])
    add_crumb "Publishers", publishers_path
    add_crumb @publisher.name
    add_crumb "Upload Subscribers"
    
    if request.post?
      @already_exists  = []
      @invalid_entries = []
      @new_entries     = []
      if params[:subscriber] && params[:subscriber][:email_addresses].present?        
        email_addresses = params[:subscriber][:email_addresses].split(/\s+/)
        if email_addresses.any?
          Rails.logger.info "email address found: #{email_addresses.inspect}"
          email_addresses.each do |email|
            unless @publisher.subscribers.find_by_email(email)
              subscriber = @publisher.subscribers.build(:email => email, :email_required => true)
              if subscriber.save
                @new_entries.push(email)
              else
                @invalid_entries.push(email) 
              end
            else
              @already_exists.push(email)
            end
          end
        end
        @message = "<strong>Information:</strong> Subscribers: [Added #{@new_entries.size}] [Already Exists #{@already_exists.size}] [Invalid #{@invalid_entries.size}] (see below for details)"
      else 
        @message = "<strong>Warning:</strong> No email addresses were found, please supply a list of email addresses."  
      end
    end
    
    render :layout => "application"
  end
  
  def new
    @publisher = Publisher.find_by_label_or_id(params[:publisher_id]||params[:publisher_label])
    @publisher_categories = Category.all_with_offers_count_for_publisher(:publisher => @publisher)
    @subscriber = @publisher.subscribers.build
    @subscriber.subscriber_referrer_code = SubscriberReferrerCode.find_by_code(params[:subscriber_referrer_code]) if params[:subscriber_referrer_code].present?
    @categories = []
    render :template => template_for_publisher(@publisher, "new"), :layout => layout_for_publisher(@publisher)
  end
  
  def create
    @publisher = Publisher.find_by_label_or_id(params[:publisher_id]) 
    @subscriber = @publisher.subscribers.new((params[:subscriber] || {}).reverse_merge(:referral_code => cookies[:referral_code], :user_agent => user_agent, :publishing_group_id => @publisher.publishing_group.try(:id)))
    if @subscriber.save
      if params[:category_id].present?
        @subscriber.categories = Category.find(params[:category_id])
      end
      analytics_tag.signup!
      cookies[:subscribed] = "subscribed"
      flash[:notice] = translate_with_theme(:subscription_success_message)
    else
      Exceptional.handle(Exception.new(@subscriber.errors.full_messages.join(", ")))
      flash[:warn] = translate_with_theme(:subscription_failure_message, :errors => @subscriber.errors.full_messages.join("<br />"))
    end
    
    respond_to do |format|
      format.html do 
        if @subscriber.valid? 
          if params[:display_thank_you_page]
            render :template => template_for_publisher(@publisher, "thank_you"), :layout => layout_for_publisher(@publisher)
          else  
            flash[:analytics_tag] = analytics_tag
            redirect_to(verify_url(params[:redirect_to]) || publisher_home_path(:label => @publisher.label)) 
          end
        else
          if params[:show_form_errors]
            @categories = []
            @publisher_categories = Category.all_with_offers_count_for_publisher(:publisher => @publisher)
            render :template => template_for_publisher(@publisher, "new"), :layout => layout_for_publisher(@publisher)
          else
            # redirect_on_failure_to used when subscription is from an outside server and we need to redirect to our own server
            redirect_to(verify_url(params[:redirect_on_failure_to]) || :back)
          end
        end
      end
      format.js
    end
  end
  
  def thank_you
    @publisher = Publisher.find_by_label_or_id(params[:publisher_id])
    render :template => template_for_publisher(@publisher, "thank_you"), :layout => layout_for_publisher(@publisher)
  end
end
