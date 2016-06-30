xml.instruct!(:xml, :version => '1.0')

xml.publishers do
  @publishers.sort_by(&:name).each do |publisher|
    xml.publisher(:id => publisher.id ) do
      xml.publisher_name(publisher.name)
      xml.publisher_href(reports_publisher_path(publisher))
      xml.facebooks_count(publisher.facebooks_count(@dates, 'DailyDeal'))
      xml.twitters_count(publisher.twitters_count(@dates, 'DailyDeal'))
    end
  end
end
