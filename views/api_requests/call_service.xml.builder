xml.instruct! :xml, :version => '1.0'

xml.service_response(:type => @service_name) do
  xml.request_id "call-#{@api_request.to_param}"
end
