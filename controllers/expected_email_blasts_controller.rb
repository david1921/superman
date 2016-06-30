class ExpectedEmailBlastsController < ApplicationController

  def index
    @publisher = Publisher.find_by_label!(params[:publisher_label])
    @expected_email_blasts = filtered_expected_email_blasts(@publisher)
    render :json => @expected_email_blasts.to_json
  end


  private

  def filtered_expected_email_blasts(publisher)
    ExpectedEmailBlast.search(publisher)
  end
end
