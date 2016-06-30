class PublishingGroupsController < ApplicationController
  include Publishers::Themes
  
  before_filter :admin_privilege_required, :except => [ :offers, :about_us, :terms, :privacy_policy]
  before_filter :load_publishing_group_by_label, :only => [ :about_us, :terms, :privacy_policy ]
  
  def index
    respond_to do |format|
      format.xml { 
        render :xml => PublishingGroup.all
      }
    end
  end

  def edit
    @publishing_group = PublishingGroup.manageable_by(current_user).find(params[:id])
  end
  
  def update 
    @publishing_group = PublishingGroup.find(params[:id])
    if @publishing_group.update_attributes(params[:publishing_group])
      flash[:notice] = "Updated #{@publishing_group.name}"
      redirect_to edit_publishing_group_path(@publishing_group)
    else
      render :edit
    end
  end
  
  def offers
    @publishing_group = PublishingGroup.find(params[:id])
    if @publishing_group
      # NOTE: this is only used by Village Voice Media at this time, so doing a regex check for 'demo' in label.
      @offers = Offer.in_publishers( @publishing_group.publishers.collect{|pub| pub.id unless pub.label =~ /demo/i}.compact ).active
    end
    
    respond_to do |format|
      format.html   { raise ActiveRecord::RecordNotFound.new(params[:id]) }
      format.wgs84  { render :file => "publishing_groups/wgs84.xml.builder", :layout => false }
    end
  end
  
  def about_us
    unless params[:layout] == "popup"
      render with_theme(:layout => "landing_pages", :template => "publishing_groups/about_us" )
    else
      render with_theme(:layout => false, :template => "publishing_groups/about_us" )
    end
  end
  
  def terms
    layout = popup? ? false : "landing_pages"
    render with_theme(:layout => layout, :template => "publishing_groups/terms" )
  end
  
  def privacy_policy
    layout = popup? ? false : "landing_pages"
    render with_theme(:layout => layout, :template => "publishing_groups/privacy_policy" )
  end

  private
  
  def load_publishing_group_by_label
    @publishing_group = PublishingGroup.find_by_label!(params[:id])    
  end
  
end
