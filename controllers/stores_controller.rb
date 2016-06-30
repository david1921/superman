class StoresController < ApplicationController
  ssl_allowed :destroy
  
  def destroy
    @store = Store.find(params[:id])
    @store.destroy
  end
end
