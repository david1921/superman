xml.instruct! :xml, :version => '1.0'

if @subscriber.valid?
  xml.response :result => "success"
else
  xml.response :result => "failure" do
    xml.errors do
      @subscriber.errors.full_messages.each do |message|
        xml.error message
      end
    end
  end
end
