xml.instruct! :xml, :version => '1.0'

root_attrs = { :type => @service_name }
root_attrs[:dates_begin] = @api_request.dates_begin.to_formatted_s if @api_request.dates_begin
root_attrs[:dates_end] = @api_request.dates_end.to_formatted_s if @api_request.dates_end

xml.service_response(root_attrs) do
  xml.counts(:type => "txt") do
    success, failure = @api_request.txt_counts
    xml.success_count success
    xml.failure_count failure
  end
  xml.counts(:type => "call") do
    success, failure = @api_request.call_counts
    xml.success_count success
    xml.failure_count failure
  end
  xml.counts(:type => "email") do
    success, failure = @api_request.email_counts
    xml.success_count success
    xml.failure_count failure
  end
end
