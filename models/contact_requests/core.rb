module ContactRequests::Core

  def deliver
    if valid?
      call_publishers_mailer :"deliver_#{self.class.name.underscore}", publisher, self
    else
      false
    end
  end

  def email_subject
    if email_subject_format.present?
      email_subject_format.dup.tap do |subject|
        attribute_names.each do |name|
          subject.gsub!(/\{\{\s*#{name.to_s}\s*\}\}/, send(name).to_s)
        end
      end
    else
      nil
    end
  end

  private

  def call_publishers_mailer(*args)
    PublishersMailer.__send__(*args)
  end

  def attribute_names
    self.class.__send__(:class_variable_get, :@@attributes).map(&:to_s)
  end

end