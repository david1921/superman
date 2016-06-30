module UrlVerifierHelper

  def verifiable_url(url)
    UrlVerifier.verifier.generate(url)
  end

end
