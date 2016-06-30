xml.instruct! :xml, :version => '1.0'

xml.service_response(:type => @service_name) do
  xml.error do
    xml.param_name @error.attr.to_s
    xml.error_code @error.code
    xml.error_string @error.text
  end
end
