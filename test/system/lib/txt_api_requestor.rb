class TxtApiRequestor < ApiRequestor
  include Test::Unit::Assertions
  attr_accessor :mobile_number, :message

  def initialize(options)
    super(options)
    @mobile_number = options[:mobile_number]
    @message = options[:message]
  end
  
  def invoke
    super "txt", { :mobile_number => mobile_number, :message => message }
  end
end
