class Publishers::SweepstakesController < ApplicationController
  include Publishers::Themes

  before_filter :user_required, :only => [ :new, :create, :edit, :update, :destroy, :admin_index, :preview]
  before_filter :load_publisher_by_label, :only => [:index, :show, :thank_you, :preview, :official_rules]
  before_filter :load_publisher_by_id, :except => [:index, :show, :thank_you, :preview, :official_rules]
  before_filter :load_sweepstake, :only => [:edit, :update, :preview, :thank_you, :clear_logo, :clear_logo_alternate, :clear_photo]
  before_filter :set_time_zone, :only => [:admin_index, :index, :new, :create, :edit, :update]  

  layout with_theme("publishers/landing_page")

  #
  # === Public actions
  #
  def index
    @featured    = @publisher.sweepstakes.active.featured.first
    @sweepstakes = @featured ? @publisher.sweepstakes.active.except( @featured ) : @publisher.sweepstakes.active
    render with_theme(:template => "publishers/sweepstakes/index") 
  end
  
  def show
    @sweepstake = @publisher.sweepstakes.active.find( params[:id] )
    render with_theme(:template => "publishers/sweepstakes/show")
  end
  
  def thank_you
    @sweepstakes = @publisher.sweepstakes.active.except( @sweepstake )
    render with_theme(:template => "publishers/sweepstakes/thank_you")
  end
  
  def official_rules
    @sweepstake = @publisher.sweepstakes.active.find( params[:id] )
    render with_theme(:template => "publishers/sweepstakes/official_rules", :layout => false)
  end
  
  #
  # === Admin actions
  #  
  def admin_index
    @sweepstakes = @publisher.sweepstakes
    add_crumb @publisher.name
    add_crumb "Sweepstakes"
    render :admin_index, :layout => "application"
  end
  
  def new
    @sweepstake = @publisher.sweepstakes.build
    add_crumb @publisher.name
    add_crumb "New Sweepstake", new_publisher_sweepstake_path(@publisher)
    render :edit, :layout => "application"
  end
  
  def create
    @sweepstake = @publisher.sweepstakes.build(params[:sweepstake])
    if @sweepstake.save
      flash[:notice] = "Sweepstake was succesfully created."
      redirect_to admin_index_publisher_sweepstakes_path( @publisher )
    else
      render :edit, :layout => "application"
    end
  end
  
  def edit
    add_crumb @publisher.name
    add_crumb "Sweepstakes", admin_index_publisher_sweepstakes_path(@publisher)
    add_crumb "Edit Sweepstake"
    render :layout => "application"
  end
  
  def update
    if @sweepstake.update_attributes(params[:sweepstake])
      flash[:notice] = "Sweepstake was successfully updated."
      redirect_to admin_index_publisher_sweepstakes_path( @publisher )
    else
      flash[:error] = "Sweepstake could not be updated."
      render :action => :edit, :layout => 'application'
    end
  end
  
  def preview
    render with_theme(:template => "publishers/sweepstakes/show")  
  end

  def clear_logo
    @sweepstake.logo.destroy
    @sweepstake.logo.clear
    @sweepstake.save!
  end

  def clear_logo_alternate
    @sweepstake.logo_alternate.destroy
    @sweepstake.logo_alternate.clear
    @sweepstake.save!
  end

  def clear_photo
    @sweepstake.photo.destroy
    @sweepstake.photo.clear
    @sweepstake.save!
  end
  
  private
  
  def load_publisher_by_label
    @publisher = Publisher.find_by_label(params[:publisher_id])    
  end
  
  def load_publisher_by_id
    @publisher = Publisher.find(params[:publisher_id])    
  end

  def load_sweepstake
    @sweepstake = @publisher.sweepstakes.find( params[:id] )
  end

  def set_time_zone
    if @publisher.present?
      Time.zone = @publisher.time_zone
    elsif @advertiser.present?
      Time.zone = @advertiser.publisher.try(:time_zone)
    elsif @sweepstake.present?
      Time.zone = @sweepstake.publisher.try(:time_zone) 
    end
    
    # Redundant?
    Time.zone ||= "Pacific Time (US & Canada)"
  end

end
