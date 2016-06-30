class PublishingGroupConsumersController < ApplicationController
  if ssl_rails_environment?
    ssl_required :show
  else
    ssl_allowed  :show
  end

  before_filter :perform_http_basic_authentication
  before_filter :assign_publishing_group_by_label
  before_filter :assign_consumer
  before_filter :authorize_user

  def show
    respond_to do |format|
      format.html do
        render :nothing => true, :status => :not_acceptable
      end
      format.json do
        render :layout => false
      end
    end
  end

  private

  def assign_publishing_group_by_label
    @publishing_group = PublishingGroup.find_by_label_or_id(params[:publishing_group_id])
    render_404 and return if @publishing_group.nil?
  end

  def assign_consumer
    @consumer = Consumer.find_by_id(params[:id])
    render_404 and return if @consumer.nil?
  end

  def authorize_user
    return if @user.has_admin_privilege?
    unless @consumer.consumer_for_publishing_group?(@publishing_group) && user_company_matches_consumer_pub_group?
      render(:nothing => true, :status => 401) and return
    end
  end

  private

  def user_company_matches_consumer_pub_group?
    if @user.company.present?
      @consumer.publisher.publishing_group.id == @user.company.id
    end
  end

end
