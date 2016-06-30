class ImagesController < ApplicationController
  before_filter :user_required
  before_filter :assign_publisher
  before_filter :can_manage?

  def index
    add_crumb "Images"
    add_crumb @publisher.name, edit_publisher_path(@publisher)
    @offers = @publisher.offers.paginate(
                             :include => :advertiser,
                             :per_page => params[:per_page ],
                             :page =>  params[ :page ]
                            )
  end
  
  
  private
  
  def assign_publisher
    @publisher = Publisher.find(params[:publisher_id])
  end
  
  def can_manage?
    unless admin? || current_user.can_manage?(@publisher)
      return access_denied
    end
  end
end
