class ApplicationMailer < ActionMailer::Base
  include Publishers::Themes
  helper "publishers/theme"
  
  # this accessor is used to handle publisher themes for the mailer.
  # if you want to use themes, then make sure to set the publisher
  # in the mailer call, like so:
  #     publisher consumer.publisher
  #
  # see ConsumerMailer#activation_request for an example.
  adv_attr_accessor :publisher

  protected
  
  class NotSending < StandardError; end

  DEFAULT_SUPPORT_EMAIL_ADDRESS = AppConfig.support_email_address || "support@analoganalytics.com"

  def self.method_missing(*args)
    super
  rescue NotSending => e
    logger.info("Not sending email #{e}")
  end

  def support_email_address(publisher)
    publisher.try(:email_only_from_support_email_address).if_present || DEFAULT_SUPPORT_EMAIL_ADDRESS
  end

  def support_sending_email_address(company = nil) 
    email_from_address = DEFAULT_SUPPORT_EMAIL_ADDRESS

    if company.is_a? Publisher
      brand_name = company.brand_name_or_name
      email_from_address = company.support_email_address.if_present || email_from_address
    else
      brand_name = company.respond_to?(:name) ? company.name : "Analog Analytics"
    end

    email_from_address.match(/\s/) ? email_from_address : "#{brand_name} <#{email_from_address}>"
  end
  
  def offer_sending_email_address(publisher = nil) 
    if publisher
      brand_name = publisher.brand_name_or_name       
      email_from_address = publisher.support_email_address.if_present || "support@txt411.com"
      email_from_address.match(/\s/) ? email_from_address : "#{brand_name} Coupons <#{email_from_address}>"
    else
      email_from_address = AppConfig.email_from_address.if_present || "support@txt411.com"
      "TXT411 Coupons <#{email_from_address}>"
    end
  end

  def daily_deal_sending_email_address(publisher)
    email_addr = AppConfig.email_from_address.if_present || "bbdsupport@analoganalytics.com"
    "#{publisher.name_for_daily_deals} <#{email_addr}>"
  end

  # this is from ActionMailer::Base, and we need to overwrite how a template
  # is looked up in order to handle themeable email templates.  
  #
  # see: vendor/rails/actionmailer/lib/action_mailer/base.rb
  def create!(method_name, *parameters) #:nodoc:
    initialize_defaults(method_name)
    __send__(method_name, *parameters)

    # If an explicit, textual body has not been set, we check assumptions.
    unless String === @body
      # First, we look to see if there are any likely templates that match,
      # which include the content-type in their file name (i.e.,
      # "the_template_file.text.html.erb", etc.). Only do this if parts
      # have not already been specified manually.
      if @parts.empty?
        Dir.glob("#{template_path}/#{@template}.*").each do |path|

          # TODO: we need to lookup with theme support, first search at publisher level, then publishing group, then default
          #template = template_root["#{mailer_name}/#{File.basename(path)}"]
          template = find_email_template_by_filename(File.basename(path))

          # Skip unless template has a multipart format
          next unless template && template.multipart?

          @parts << ActionMailer::Part.new(
            :content_type => template.content_type,
            :disposition => "inline",
            :charset => charset,
            :body => render_message(template, @body)
          )
        end
        unless @parts.empty?
          @content_type = "multipart/alternative" if @content_type !~ /^multipart/
          @parts = sort_parts(@parts, @implicit_parts_order)
        end
      end

      # Then, if there were such templates, we check to see if we ought to
      # also render a "normal" template (without the content type). If a
      # normal template exists (or if there were no implicit parts) we render
      # it.
      template_exists = @parts.empty?
      template_exists ||= find_email_template_by_filename(@template)
      @body = render_message(@template, @body) if template_exists

      # Finally, if there are other message parts and a textual body exists,
      # we shift it onto the front of the parts and set the body to nil (so
      # that create_mail doesn't try to render it in addition to the parts).
      if !@parts.empty? && String === @body
        @parts.unshift ActionMailer::Part.new(:charset => charset, :body => @body)
        @body = nil
      end
    end

    # If this is a multipart e-mail add the mime_version if it is not
    # already set.
    @mime_version ||= "1.0" if !@parts.empty?

    # build the mail object itself
    @mail = create_mail
  end

  # responsible for looking up the appropriate template for the email.
  # if a publisher is set, then we try and look for a customized template
  # for the publisher (or publishing group).  if there is no publisher
  # then we default to the current ActionMailer::Base way.
  def find_email_template_by_filename(filename)
    template = nil
    if @publisher
      template ||= template_root["themes/#{@publisher.label}/#{mailer_name}/#{filename}"]
      template ||= template_root["themes/#{@publisher.publishing_group.label}/#{mailer_name}/#{filename}"] if @publisher.publishing_group
    end
    template ||= template_root["#{mailer_name}/#{filename}"]
    template
  end

end
