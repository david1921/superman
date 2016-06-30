class Publishers::SweepstakeEntriesController < ApplicationController
  include Publishers::Themes

  before_filter :user_required,                 :only => [:admin_index]
  before_filter :load_pubilsher_by_id,          :only => [:admin_index]
  before_filter :load_sweepstake_by_id,         :only => [:admin_index]

  before_filter :load_publisher_by_label,       :only => [:create]
  before_filter :load_active_sweepstake_by_id,  :only => [:create]


  #
  # === Admin actions
  #
  def admin_index
    @sweepstake_entries = @sweepstake.entries
    add_crumb @publisher.name
    add_crumb "Sweepstakes", admin_index_publisher_sweepstakes_path(@publisher)
    add_crumb "Entries"
  end


  #
  # === Public actions
  #
  def create
    consumer = current_consumer if consumer?
    if @publisher.force_password_reset?(email_from_params)
      redirect_to consumer_password_reset_path_or_url(@publisher)
      return
    end
    consumer ||= login_in_consumer
    consumer ||= create_new_consumer
    @sweepstake_entry = @sweepstake.entries.build( params[:sweepstake_entry].merge(:consumer => consumer) )
    if @sweepstake_entry.save
      redirect_to thank_you_publisher_sweepstake_path( @publisher.label, @sweepstake )
    else
      @errors = @sweepstake_entry.errors.full_messages
      render with_theme( :template => "publishers/sweepstakes/show", :layout => "publishers/landing_page" )
    end
  end


  private

  def load_pubilsher_by_id
    @publisher = Publisher.find(params[:publisher_id])
  end

  def load_sweepstake_by_id
    @sweepstake = @publisher.sweepstakes.find( params[:sweepstake_id] )
  end

  def load_publisher_by_label
    @publisher = Publisher.find_by_label(params[:publisher_id])
  end

  def load_active_sweepstake_by_id
    @sweepstake = @publisher.sweepstakes.active.find( params[:sweepstake_id] )
  rescue ActiveRecord::RecordNotFound
    redirect_to publisher_sweepstakes_path( @publisher.label )
  end

  def login_in_consumer
    session   = params[:session] || {}
    if session[:email].present? || session[:password].present?
      consumer = Consumer.authenticate(@publisher, session[:email].try(:strip), session[:password])
      set_up_session consumer
      consumer
    end
  end

  def create_new_consumer
    sweepstake_entry_params = params[:sweepstake_entry] || {}
    consumer_params         = params[:consumer] || {}
    consumer = @publisher.consumers.create( consumer_params.merge( :agree_to_terms => sweepstake_entry_params[:agree_to_terms] ) )
    if consumer.valid?
      consumer.activate!
      set_up_session consumer
    end
    consumer
  end

  def email_from_params
    session = params[:session]
    session && session[:email].try(:strip)
  end

end
