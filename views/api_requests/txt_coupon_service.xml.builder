xml.instruct! :xml, :version => '1.0'

xml.service_response(:type => @service_name) do
  xml.txt_coupon_id @api_request.txt_offer.to_param
end
