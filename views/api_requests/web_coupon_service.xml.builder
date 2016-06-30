xml.instruct! :xml, :version => '1.0'

xml.service_response(:type => @service_name) do
  xml.web_coupon_id @api_request.offer.to_param
end
