class ApiRequest < ActiveRecord::Base
  belongs_to :publisher

  UNATTRIBUTED_ERROR      = [1, "Unattributed error"]
  INVALID_PHONE_NUMBER    = [2, "Invalid phone number"]
  INVALID_CONTENT_LENGTH  = [3, "Invalid content length"]
  MISSING_EMAIL_SUBJECT   = [4, "Missing email subject"]
  INVALID_EMAIL_ADDRESS   = [5, "Invalid email address"]
  INVALID_DATE            = [6, "Invalid date"]
  PARAMETER_VALIDATION    = [7, "Validation errors: %s"]
  
  class Error
    attr_reader :attr, :code, :text
    
    def initialize(code, text, attr)
      @code, @text, @attr = code, text, attr
    end
  end
  
  class UnattributedError < Error
    def initialize(message)
      super(1, "Unattributed error (%s)" % message, nil)
    end
  end

  class InvalidPublisherLabelError < Error
    def initialize(attr=nil)
      super(*INVALID_PUBLISHER_LABEL + [attr])
    end
  end

  class InvalidPhoneNumberError < Error
    def initialize(attr=nil)
      super(*INVALID_PHONE_NUMBER + [attr])
    end
  end

  class InvalidContentLengthError < Error
    def initialize(attr=nil)
      super(*INVALID_CONTENT_LENGTH + [attr])
    end
  end

  class MissingEmailSubjectError < Error
    def initialize(attr=nil)
      super(*MISSING_EMAIL_SUBJECT + [attr])
    end
  end

  class InvalidEmailAddressError < Error
    def initialize(attr=nil)
      super(*INVALID_EMAIL_ADDRESS + [attr])
    end
  end

  class InvalidDateError < Error
    def initialize(attr=nil)
      super(*INVALID_DATE + [attr])
    end
  end
  
  class ParameterValidationError < Error
    def initialize(attr, messages)
      messages = Array.wrap(messages)
      super(PARAMETER_VALIDATION[0], PARAMETER_VALIDATION[1] % messages.map { |message| "%s %s" % [attr, message] }.join(", "), attr)
    end
  end
  
  protected
  
  def normalize_report_group
    self.report_group = report_group.to_s.strip
  end
end
