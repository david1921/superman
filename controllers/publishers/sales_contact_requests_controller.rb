class Publishers::SalesContactRequestsController < Publishers::ContactRequestsController
  def new
    @sales_contact_request = SalesContactRequest.new
    render with_theme(:template => "publishers/sales_contact_requests/new")
  end

  def create
    @sales_contact_request = SalesContactRequest.new(params[:sales_contact_request].merge(:publisher => @publisher))

    if @sales_contact_request.deliver
      redirect_to thank_you_publisher_sales_contact_requests_path(@publisher)
    else
      render with_theme(:template => "publishers/sales_contact_requests/new")
    end
  end

  def thank_you
    render with_theme(:template => "publishers/sales_contact_requests/thank_you")
  end
end
