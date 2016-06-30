module Users
  
  module ActiveSession

    def reset_active_session_token!
      self.active_session_token = generate_new_active_session_token
      begin
        save!
      rescue Exception => e
        Rails.logger.warn "Failed to reset active session token for User #{id}: #{e.class}: #{e.message}"
      end
    end

    def generate_new_active_session_token
      ActiveSupport::SecureRandom.hex(16)
    end
   
  end

end
