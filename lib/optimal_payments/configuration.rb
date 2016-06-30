module OptimalPayments

  class Configuration
    
    # the available environments for OptimalPayments
    ENVIRONMENTS  = [:production, :test]
    CONFIGURATION = {
      :test => {
        :base_url       => "https://checkout.test.optimalpayments.com/securePayment/op",
        :webservice_url => "https://webservices.test.optimalpayments.com/creditcardWS/CreditCardServlet/v1"
      },
      :production => {
        :base_url       => "https://checkout.optimalpayments.com/securePayment/op",
        :webservice_url => "https://webservices.optimalpayments.com/creditcardWS/CreditCardServlet/v1"
      }
    }
    
    # for Checkout API
    cattr_accessor :shop_id, :private_key

    # for WebService API
    cattr_accessor :accountNum, :storeID, :storePwd

    # sets the optimal payment environment to use.  the default is :test
    # acceptable values are :production or :test
    def self.environment=(value = "")                                                                             
      value = value.to_sym
      raise ArgumentError, "environment can only be :production or :test" unless ENVIRONMENTS.include?( value )
      @environment = value
    end
    
    def self.environment
      @environment ||= :test
    end
    
    # the base url for the OptimalPayment API calls
    def self.base_url
      @base_url ||= CONFIGURATION[ self.environment ][:base_url]
    end 
    
    def self.webservice_url
      @webservice_url ||= CONFIGURATION[ self.environment ][:webservice_url]
    end
    
    
  end  
  
end