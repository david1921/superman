class UsersController < ApplicationController
  helper_method :parent_users_url, :parent_user_url, :edit_parent_user_url
  
  def index
    @users = @parent.users
    set_crumb_prefix @parent
    render :template => "users/index"
  end
  
  def new
    @user = User.new
    @user.user_companies << UserCompany.new(:company => @parent)

    set_crumb_prefix @parent
    add_crumb_for_action :new
    render :template => "users/edit"
  end
  
  def create
    @user = User.new(params[:user])
    @user.user_companies << UserCompany.new(:company => @parent)

    if @user.save
      flash[:notice] = "Created #{@user.name}"
      redirect_to parent_users_url
    else
      flash[:error]  = "Could not create user"
      set_crumb_prefix @parent
      add_crumb_for_action :new
      render :template => "users/edit"
    end
  end

  def edit
    @user = @parent.users.find(params[:id])
    set_crumb_prefix @parent
    add_crumb @user.name
    add_crumb_for_action :edit, @user
    render :template => "users/edit"
  end
  
  def update
    @user = @parent.users.find(params[:id])
    @user.attributes = params[:user]

    if @user.save
      flash[:notice] = "Updated #{@user.name}"
      redirect_to parent_users_url
    else
      set_crumb_prefix @parent
      add_crumb @user.name
      add_crumb_for_action :edit, @user
      render :template => "users/edit"
    end
  end
  
  def delete
    users = @parent.users.find(params[:id])
    users.each(&:force_destroy)
    flash[:notice] = "Deleted #{params[:id].size} #{params[:id].size > 1 ? 'users' : 'user'}"
    redirect_to parent_users_url
  end
  
  private

  def parent_type
    @parent.class.name.underscore
  end
  
  def add_crumb_for_action(action, *args)
    text = action.to_s.humanize
    path = send("#{action}_#{parent_type}_user_path", @parent, *args)
    add_crumb text, path
  end
  
  def parent_users_url
    send("#{parent_type}_users_url", @parent)
  end

  def parent_user_url(user)
    send("#{parent_type}_user_url", @parent, user)
  end

  def edit_parent_user_url(user)
    send("edit_#{parent_type}_user_url", @parent, user)
  end

end
