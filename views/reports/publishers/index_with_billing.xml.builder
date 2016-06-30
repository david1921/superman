xml.instruct! :xml, :version => '1.0'

xml.publishers_billing_summary :dates_begin => @dates.begin, :dates_end => @dates.end do
  @publishers.sort_by(&:name).each do |publisher|
    xml.publisher(:publisher_id => publisher.id) do
      xml.publisher_name(publisher.name)
      xml.prints_count(publisher.prints_count(@dates))
      xml.emails_count(publisher.emails_count(@dates))
      xml.txts_count(publisher.txts_count(@dates))
      xml.calls_count(publisher.voice_messages_count(@dates))
      xml.calls_minutes(number_with_precision(publisher.voice_messages_minutes(@dates), :precision => 1))
    end
  end
end
