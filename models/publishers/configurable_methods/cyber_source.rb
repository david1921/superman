module Publishers::ConfigurableMethods::CyberSource
  def self.included(base)
    base.send :include, HasConfigurableMethods
  
    base.configurable_method :cyber_source_credit_options, :key => :label, :parent => :publishing_group
  
    base.configurable_methods_for "entertainment" do
      def cyber_source_credit_options(daily_deal_purchase)
        {
          :billing => {
            :email => daily_deal_purchase.consumer.email
          }, 
          :merchant_defined => {
            :field_1 => "52278",
            :field_2 =>  daily_deal_purchase.publisher.label,
            :field_3 =>  daily_deal_purchase.daily_deal.listing
          }
        }
      end
    end
  end
end
