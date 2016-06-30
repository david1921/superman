class Publishers::SupportContactRequestsController < Publishers::ContactRequestsController
  def new
    @contact_request = SupportContactRequest.new
    render with_theme(:template => "publishers/support_contact_requests/new")
  end

  def create
    @contact_request = SupportContactRequest.new(params[:support_contact_request].merge(:publisher => @publisher))

    if @contact_request.deliver
      redirect_to thank_you_publisher_support_contact_requests_path(@publisher)
    else
      render with_theme(:template => "publishers/support_contact_requests/new")
    end
  end

  def thank_you
    render with_theme(:template => "publishers/support_contact_requests/thank_you")
  end
end
