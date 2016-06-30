xml.instruct! :xml, :version => '1.0'

xml.services do
  @api_services.each do |name, href|
    xml.service do
      xml.name name
      xml.link :href => href
    end
  end
end
