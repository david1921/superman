module Drop
  class User < Liquid::Drop
    delegate :first_name, :errors, :to => :user

    def initialize(user)
      @user = user
    end
    
    def full_error_messages
      user.errors.full_messages
    end
    
    def user
      @user
    end
  end
end
