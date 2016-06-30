module UrlVerifier

  def self.verifier
    @@_url_verifier ||= ActiveSupport::MessageVerifier.new(AppConfig.message_verifier_secret)
  end

  def verify_url(url)
    return url if url.blank?

    begin
      UrlVerifier.verifier.verify(url)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      argument_error = ArgumentError.new(
        "'#{url}' is not a verifiable URL. Are you rendering this URL as, e.g., a redirect_to form parameter? " +
        "If so, try verifiable_url(url) instead.")
      Exceptional.handle(argument_error)
      if Rails.env.production?
        url
      else
        raise argument_error
      end
    end
  end

end
