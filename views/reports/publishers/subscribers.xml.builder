xml.instruct! :xml, :version => '1.0'

xml.subscribers do
  @subscribers.each do |subscriber|
    xml.subscriber :id => subscriber.id do
      xml.email       subscriber.email
      xml.zip_code    subscriber.zip_code
      xml.first_name  subscriber.first_name
      xml.last_name   subscriber.last_name
    end
  end
end
