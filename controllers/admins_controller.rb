class AdminsController < ApplicationController
  before_filter :full_admin_privilege_required
  
  def show
    @user = User.find(params[:id])
    if @user.has_admin_privilege?
      flash[:warn] = "Resetting an admin user's password is not allowed"
    end
  end
  
  def index
    @users = User.with_admin_privilege.all(:order => "admin_privilege ASC, name ASC")
  end
  
  def new
    @user = User.new
    @user.admin_privilege = current_user.admin_privilege
    render :action => :edit
  end
 
  def create
    @user = User.new(params[:user])

    if params[:user][:admin_privilege] == User::FULL_ADMIN && !current_user.has_full_admin_privileges?
      flash.now[:error] = "Sorry, you do not have permission to do that"
      render :action => :edit
      return
    end

    @user.admin_privilege = params[:user][:admin_privilege]
    User.transaction do
      if @user.save
        if @user.has_restricted_admin_privileges?
          @user.set_companies(:publisher_ids => params[:manageable_publisher_ids],
                              :publishing_group_ids => params[:manageable_publishing_group_ids])
        end
        flash[:notice] = "Created #{@user.email}"
        redirect_to admins_path
      else
        flash[:error]  = "Could not create user"
        render :action => :edit
      end
    end
  end

  def edit
    @user = User.with_admin_privilege.find(params[:id])
  end
  
  def update
    @user = User.with_admin_privilege.find(params[:id])
    
    if params[:user][:admin_privilege] == User::FULL_ADMIN && !current_user.has_full_admin_privileges?
      flash.now[:error] = "Sorry, you do not have permission to do that"
      render :action => :edit
      return
    end

    User.transaction do
      if @user.update_attributes(params[:user])
        if @user.has_restricted_admin_privileges?
          @user.set_companies(:publisher_ids => params[:manageable_publisher_ids],
                              :publishing_group_ids => params[:manageable_publishing_group_ids])
        end
        flash[:notice] = "Updated #{@user.name}"
        redirect_to admins_path
      else
        render :action => :edit
      end
    end
  end
  
  def delete
    if params[:id]
      users = User.with_admin_privilege.find_all_by_id(params[:id])
      users.map(&:force_destroy)
      flash[:notice] = "Deleted #{users.size != 1 ? 'admins' : 'admin'}"
    end
    redirect_to admins_path
  end
  
  def randomize_password
    @user = User.find(params[:id])
    unless @user.has_admin_privilege?
      @password = User.random_password(6)
      @user.update_attributes! :password => @password, :password_confirmation => @password
    else
      flash[:warn] = "Resetting an admin user's password is not allowed"
    end
    render :action => :show
  end
end
