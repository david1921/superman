class Advertisers::AdvertiserOwnersController < Advertisers::AdminController

  if ssl_rails_environment?
    ssl_required :create, :update, :new, :edit, :destroy
  else
    ssl_allowed  :create, :update, :new, :edit, :destroy
  end
  ssl_allowed :create, :update, :new, :edit, :destroy

  def create
    @owner = @advertiser.advertiser_owners.build( params[:advertiser_owner] )
    if @owner.save
      flash[:notice] = "Created a new owner for #{@advertiser.name}"
      redirect_to edit_advertiser_path( @advertiser )
    else
      render 'new'
    end
  end
 
  def new
    set_crumb_prefix @advertiser.publisher
    add_crumb @advertiser.name
    add_crumb "Edit", edit_advertiser_path(@advertiser)
  end 

  def edit
    set_crumb_prefix @advertiser.publisher
    add_crumb @advertiser.name
    add_crumb "Edit", edit_advertiser_path(@advertiser)
    @owner = @advertiser.advertiser_owners.find( params[:id] )
  end

  def update
    @owner = @advertiser.advertiser_owners.find( params[:id] )
    if @owner.update_attributes( params[:advertiser_owner] )
      flash[:notice] = "Updated advertiser #{@advertiser.name}"
      redirect_to edit_advertiser_path( @advertiser )
    else
      render 'edit'
    end
  end

  def destroy
    @owner = @advertiser.advertiser_owners.find( params[:id] )
    @owner.destroy
    flash[:notice] = "Deleted the advertiser's owner"
    redirect_to edit_advertiser_path( @advertiser )
  end
private

  def set_crumb_prefix(publisher)
    if admin?
      add_crumb "publishers", publishers_path
    end
    if publishing_group?
      add_crumb "publishers", publishing_group_publishers_path(current_user.company)
    end
    if admin? || publishing_group? || publisher?
      add_crumb publisher.name
      add_crumb "advertisers", publisher_advertisers_path(publisher)
    end
  end
end
