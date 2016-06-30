module Debug
  class SimpleTestEmailSender
    # resque queue
    @queue = :email
    def self.perform(recipients)
      AnalogMailer.deliver_simple_test_email(recipients)
    end
  end
end