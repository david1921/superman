class CallApiRequestor < ApiRequestor
  include Test::Unit::Assertions
  attr_accessor :consumer_phone_number, :merchant_phone_number

  def initialize(options)
    super(options)
    @consumer_phone_number = options[:consumer_phone_number]
    @merchant_phone_number = options[:merchant_phone_number]
  end
  
  def invoke
    super "call", { :consumer_phone_number => consumer_phone_number, :merchant_phone_number => merchant_phone_number }
  end
end
