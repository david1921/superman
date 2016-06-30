xml.instruct! :xml, :version => '1.0'

xml.service_response(:type => "api") do
  xml.error do
    xml.param_name nil
    xml.error_code 0
    xml.error_string "Missing or invalid API-Version header: current version is 1.2.0"
  end
end
