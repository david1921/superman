class MailChimpConfigurationError < StandardError; end

module MailChimpListManagement
  
  DEFAULT_BATCH_SIZE = 1000
  
  def update_mailchimp_list(options = {})
    setup_mailchimp!
    send_emails_to_mailchimp_in_batches(options)
  end
  
  def mailchimp_lists_by_name(name)
    setup_mailchimp!
    @mailchimp.lists_by_name(name)
  end
  
  def mailchimp_api_key
    mailchimp_config && mailchimp_config["api_key"]
  end
  
  def mailchimp_list_id
    mailchimp_config && mailchimp_config["list_id"]
  end
  
  protected
  
  def send_emails_to_mailchimp_in_batches(options)
    added, updated, errors = 0, 0, []
    emails_to_send_mailchimp(options).each_slice(mailchimp_batch_size(options)) do |email_batch|
      mc_result = @mailchimp.list_batch_subscribe :id => mailchimp_list_id,
                                                  :emails => email_batch,
                                                  :double_optin => false,
                                                  :update_existing => true
      added += mc_result[:added]
      updated += mc_result[:updated]
      errors += mc_result[:errors]
    end
    
    { :added => added, :updated => updated, :errors => errors }
  end

  def emails_to_send_mailchimp(options)
    interval = options.has_key?(:period) ? options[:period] / 1.hour : nil
    @emails_to_send_mailchimp ||= Set.new(signups(interval).try(:map) { |s| s["email"] })
  end
  
  def mailchimp_batch_size(options)
    @batch_size ||= options.fetch(:batch_size, DEFAULT_BATCH_SIZE)
  end
  
  def mailchimp_config
    @config ||= YAML.load_file(Rails.root.join("config", "mailchimp.yml"))
    @config[label] || @config[publishing_group.try(:label)]
  end
  
  def setup_mailchimp!
    @mailchimp ||= begin
      unless mailchimp_api_key.present?
        raise MailChimpConfigurationError, "Missing MailChimp api key for publisher #{label}"
      end
    
      unless mailchimp_list_id.present?
        raise MailChimpConfigurationError, "Missing MailChimp list id for publisher #{label}"
      end
    
      MailChimp.new :apikey => mailchimp_api_key
    end
  end
  
end
