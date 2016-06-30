class Analog::Util::EmailValidator

  # This is purposefully imperfect -- it's just a check for bogus input. See
  # http://www.regular-expressions.info/email.html
  RE_EMAIL_NAME   = '[\w\.%\+\-\']+'
  RE_DOMAIN_HEAD  = '(?:[A-Z0-9\-]+\.)+'
  RE_DOMAIN_TLD   = '(?:com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|museum|coop|int|pro|tel|travel|cat|asia|[A-Z]{2})'

  RE_EMAIL_OK     = /\A#{RE_EMAIL_NAME}@#{RE_DOMAIN_HEAD}#{RE_DOMAIN_TLD}\z/i

  def valid_email?(email)
    email  =~ RE_EMAIL_OK
  end

end
