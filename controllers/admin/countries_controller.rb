class Admin::CountriesController < ApplicationController

  if ssl_rails_environment?
    ssl_required :index
  end

  before_filter :admin_privilege_required

  def index
    @active_countries = Country.active
    @inactive_countries = Country.inactive
  end

  def edit
    @country = Country.find(params[:id])
  end

  def update
    @country = Country.find(params[:id])
    respond_to do |format|
      if @country.update_attributes(params[:country])
        format.html { redirect_to(admin_countries_url, :notice => "Country #{@country.name} was updated.") }
      else
        format.html { render :action => "edit" }
      end
    end
  end

end
