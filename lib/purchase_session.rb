module PurchaseSession

  PURCHASE_SESSION_TOKEN_KEY = :purchase_session_token

  def set_purchase_session(token)
    session[PURCHASE_SESSION_TOKEN_KEY] = token if token.present?
  end

  def has_matching_purchase_session?(token)
    session[PURCHASE_SESSION_TOKEN_KEY] == token
  end

  def kill_purchase_session!
    session[PURCHASE_SESSION_TOKEN_KEY] = nil
  end

end