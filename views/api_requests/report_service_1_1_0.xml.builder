xml.instruct! :xml, :version => '1.0'

root_attrs = { :type => @service_name }
root_attrs[:dates_begin] = @api_request.dates_begin.to_formatted_s if @api_request.dates_begin
root_attrs[:dates_end] = @api_request.dates_end.to_formatted_s if @api_request.dates_end

xml.service_response(root_attrs) do
  @api_request.counts.each do |counts|
    xml.group(:tag => counts.report_group) do
      xml.counts(:type => "txt") do
        xml.success_count counts.txts_count_success
        xml.failure_count counts.txts_count_failure
      end
      xml.counts(:type => "call") do
        xml.success_count counts.calls_count_success
        xml.failure_count counts.calls_count_failure
      end
      xml.counts(:type => "email") do
        xml.success_count counts.emails_count_success
        xml.failure_count counts.emails_count_failure
      end
    end
  end
end
