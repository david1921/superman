require File.dirname(__FILE__) + "/../../test_helper"

class ConsumerMailerTest < ActionMailer::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  test "password_reset_instructions" do
    consumer = Factory(:consumer)
    ConsumerMailer.deliver_password_reset_instructions(consumer)

    assert_equal 1, ActionMailer::Base.deliveries.size, "Should generate one email"
    email = ActionMailer::Base.deliveries.first
    assert_equal 1, email.parts.size, "Parts"
    body = email.parts.first.body
    assert_match %r{Please click on the this link to change your password}, body, "Please click ... text should be in email"
    assert_match %r{http://sb1.analoganalytics.com/pw/\d+/.+}, body, "Should include password reset link"
  end
  
  test "password reset email signature" do
    publisher = Factory(:publisher, :brand_name => "Our Brand Name")
    consumer = Factory(:consumer, :publisher => publisher)
    consumer_mail = ConsumerMailer.create_password_reset_instructions(consumer)
    body = consumer_mail.parts.first.body    
    assert_match /this email.\n\nThanks,\n\nOur Brand Name/, body
    
    publisher.daily_deal_email_signature = "Cheers,\n\nThe Foobar Team"
    consumer_mail = ConsumerMailer.create_password_reset_instructions(consumer)
    body = consumer_mail.parts.first.body
    assert_match /this email.\n\nCheers,\n\nThe Foobar Team/, body
  end

  test "activation request email signature" do
    publisher = Factory(:publisher, :brand_name => "Our Brand Name")
    consumer = Factory(:consumer, :publisher => publisher)
    consumer_mail = ConsumerMailer.create_activation_request(consumer)
    body = consumer_mail.parts.first.body    
    assert_match /\w+\n\nThanks,\n\nOur Brand Name/, body
    
    publisher.daily_deal_email_signature = "Cheers,\n\nThe Foobar Team"
    consumer_mail = ConsumerMailer.create_activation_request(consumer)
    body = consumer_mail.parts.first.body
    assert_match /\w+\n\nCheers,\n\nThe Foobar Team/, body
  end
  
  test "activation request html part with publisher daily deal logo" do
    publisher = Factory(:publisher, :daily_deal_logo => File.open('test/fixtures/files/advertiser_logo.png'))
    consumer = Factory(:consumer, :publisher => publisher)
    email = ConsumerMailer.create_activation_request(consumer)
    assert_not_nil (html_part = email.parts.select{|p| p.content_type == 'text/html' }.first), 'Expected html part'
    assert_match %r{<img src="#{Regexp.escape publisher.daily_deal_logo.url}"}, html_part.body, 'Expected publisher logo'
  end

  context "translations" do
    
    context "activation request email in locale 'en'" do
      
      setup do
        @consumer = Factory :consumer, :preferred_locale => "en"
        @activation_request = ConsumerMailer.create_activation_request(@consumer)
        @html_part = @activation_request.parts.detect { |p| p.content_type == "text/html" }
        @text_part = @activation_request.parts.detect { |p| p.content_type == "text/plain" }
      end
      
      should "show the subject in locale 'en'" do
        assert_equal "Important: Verify your email address!", @activation_request.subject
      end
      
      should "show the opening in locale 'en'" do
        assert_match /Dear .+/, @html_part.body
        assert_match /Dear .+/, @text_part.body
      end
      
      should "show the 'following this link' instruction in locale 'en'" do
        assert_match /following this link/, @html_part.body
        assert_match /following this link/, @text_part.body
      end
      
      should "show the copy and paste instruction in locale 'en'" do
        assert_match /if clicking on the link doesn't work/i, @html_part.body
        assert_match /if clicking on the link doesn't work/i, @text_part.body
      end
      
      should "show the email signature in locale 'en'" do
        assert_match /Thanks,/, @html_part.body
        assert_match /Thanks,/, @text_part.body
      end
      
    end
    
    context "activation request email in locale 'es-MX'" do
      
      setup do
        I18n.locale = "es-MX"
        @consumer = Factory :consumer
        @activation_request = ConsumerMailer.create_activation_request(@consumer)
        @html_part = @activation_request.parts.detect { |p| p.content_type == "text/html" }
        @text_part = @activation_request.parts.detect { |p| p.content_type == "text/plain" }
      end
      
      should "show the subject in locale 'es-MX'" do
        assert_equal "¡Aviso! Por favor verifíque la dirección de su correo electrónico.", @activation_request.subject
      end
      
      should "show the opening in locale 'es-MX'" do
        assert_match /Estimado .+/, @html_part.body
        assert_match /Estimado .+/, @text_part.body
      end
      
      should "show the 'follow this link' instruction in locale 'es-MX'" do
        assert_match /Para poder activar su cuenta/i, @html_part.body
        assert_match /Para poder activar su cuenta/i, @text_part.body        
      end
      
      should "show the copy and paste instruction in locale 'es-MX'" do
        assert_match /Si el enlace no funciona/i, @html_part.body
        assert_match /Si el enlace no funciona/i, @text_part.body                
      end
      
      should "show the email signature in locale 'es-MX'" do
        assert_match /Gracias,/i, @html_part.body
        assert_match /Gracias,/i, @text_part.body                
      end
      
    end

    context "password reset email in locale 'en'" do
      
      setup do
        I18n.locale = "en"
        @consumer = Factory :consumer
        @pw_reset = ConsumerMailer.create_password_reset_instructions(@consumer)
        @text_part = @pw_reset.parts.detect { |p| p.content_type = "text/plain" }
      end
      
      should "set the subject line in locale 'en'" do
        assert_equal "Resetting your password", @pw_reset.subject
      end
      
      should "show the opening salutation in locale 'en'" do
        assert_match /Dear .+/, @pw_reset.body
      end
      
      should "show the 'please click this link' paragraph in locale 'en'" do
        assert_match /Please click on the this link/i, @pw_reset.body
      end
      
      should "show the 'if clicking' paragraph in locale 'en'" do
        assert_match /If clicking on the link doesn't work/i, @pw_reset.body
      end
      
      should "show the 'Note' paragraph in locale 'en'" do
        assert_match /Note: We received a request to reset your password/i, @pw_reset.body
      end
      
      should "show the valediction in locale 'en'" do
        assert_match /Thanks,/, @pw_reset.body
      end

    end
    
    context "password reset email in locale 'es-MX'" do
      
      setup do
        I18n.locale = "es-MX"
        @consumer = Factory :consumer
        @pw_reset = ConsumerMailer.create_password_reset_instructions(@consumer)
        @text_part = @pw_reset.parts.detect { |p| p.content_type = "text/plain" }
      end
      
      should "set the subject line in locale 'es-MX'" do
        assert_equal "Cambiar contraseña", @pw_reset.subject
      end
      
      should "show the opening salutation in locale 'es-MX'" do
        assert_match /Estimado .+/, @pw_reset.body
      end
      
      should "show the 'please click this link' paragraph in locale 'es-MX'" do
        assert_match /Por favor haga clic/i, @pw_reset.body
      end
      
      should "show the 'if clicking' paragraph in locale 'es-MX'" do
        assert_match /Si el enlace no funciona/i, @pw_reset.body
      end
      
      should "show the 'Note' paragraph in locale 'es-MX'" do
        assert_match /Notese: Usted ha recibido este/i, @pw_reset.body
      end
      
      should "show the valediction in locale 'es-MX'" do
        assert_match /Gracias,/, @pw_reset.body
      end

    end
    
    
  end

  context "wcax publications" do

    setup do
      pg = Factory(:publishing_group, :label => "wcax")
      @publisher = Factory(:publisher, :publishing_group => pg, :label => "wcax-vermont", :name => "Jumponit Vermont")
      @consumer  = Factory(:consumer, :publisher => @publisher)
    end

    context "activation request email" do
      should "generate the wcax version" do
        email = ConsumerMailer.create_activation_request(@consumer)
        body = email.body
        assert_equal 2, email.parts.size
        assert_match "Dear #{@consumer.first_name},", body
        assert_match "To activate your new jumponit account, please verify your email address by following this link:", body
        assert_match %r{http://sb1.analoganalytics.com/publishers/\d+/consumers/activate\?activation_code=}, body, "Should include password reset link"
        assert_match "If clicking on the link doesn't work, you can also copy and paste the following code into the activation screen during signup:", body
        assert_match "Thanks,", body
        assert_match "Jumponit Vermont Customer Support", body
      end
    end
  end
  
end
