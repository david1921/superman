xml.instruct! :xml, :version => '1.0'

xml.errors do
  @request.error.messages.each do |message|
    xml.error do
      xml.text message
    end
  end
end
