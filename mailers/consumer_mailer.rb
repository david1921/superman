class ConsumerMailer < ApplicationMailer
  helper :consumers
  
  # this is using the new themeable bits for the email templates.
  # themeable templates come into play once you set the publisher, 
  # like the first line below.
  def activation_request(consumer)
    publisher consumer.publisher
    I18n.locale = consumer.preferred_locale if consumer.preferred_locale.present?
    # ¡Aviso! Por favor verifíque la dirección de su correo electrónico.
    subject Analog::Themes::I18n.t(consumer.publisher, "consumers.activation_request.subject")
    recipients consumer.email
    from daily_deal_sending_email_address(consumer.publisher)
    sent_on Time.now
    body :consumer => consumer
  end

  def password_reset_instructions(consumer)
    publisher consumer.publisher
    I18n.locale = consumer.preferred_locale if consumer.preferred_locale.present?
    subject Analog::Themes::I18n.t(consumer.publisher, "consumers.password_reset.subject")
    recipients consumer.email
    from daily_deal_sending_email_address(consumer.publisher)
    sent_on Time.now

    body :consumer => consumer
  end
  
  def welcome_message(consumer)
    subject I18n.t("consumers.welcome_message.subject")
    recipients consumer.email
    from daily_deal_sending_email_address(consumer.publisher)
    sent_on Time.now
    body :consumer => consumer, :publisher => consumer.publisher
  end
  
  def api_password_reset_instructions(consumer)
    subject "Resetting your password"
    recipients consumer.email
    from daily_deal_sending_email_address(consumer.publisher)
    sent_on Time.now
    body :consumer => consumer
  end
end
