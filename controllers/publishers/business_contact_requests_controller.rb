class Publishers::BusinessContactRequestsController < Publishers::ContactRequestsController
  def new
    @contact_request = BusinessContactRequest.new
    render with_theme(:template => "publishers/business_contact_requests/new")
  end

  def create
    @contact_request = BusinessContactRequest.new(params[:business_contact_request].merge(:publisher => @publisher))

    if @contact_request.deliver
      redirect_to thank_you_publisher_business_contact_requests_path(@publisher)
    else
      render with_theme(:template => "publishers/business_contact_requests/new")
    end
  end

  def thank_you
    render with_theme(:template => "publishers/business_contact_requests/thank_you")
  end
end
