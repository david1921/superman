module DailyDealVariationsHelper

  def travelsavers_product_code_is_editable?(daily_deal, daily_deal_variation)
    !daily_deal.syndicated? && daily_deal_variation.travelsavers_product_code_is_editable?    
  end

  def daily_deal_variations_index_hash(daily_deal)
    daily_deal.daily_deal_variations.map do |ddv|
      hash = { :value_proposition => ddv.value_proposition,
        :value => ddv.value.to_f,
        :price => ddv.price.to_f,
        :minimum_purchase_quantity => ddv.min_quantity,
        :maximum_purchase_quantity => ddv.max_quantity,
        :quantity_sold => ddv.number_sold,
        :daily_deal_variation_id => ddv.id,
        :total_quantity_available => ddv.quantity,
        :terms => ddv.terms
      }
      hash.merge!(:methods => {:purchase_url => new_daily_deal_daily_deal_purchase_url(daily_deal,
                                                                    :daily_deal_variation_id => ddv.to_param,
                                                                    :host => daily_deal.publisher.production_daily_deal_host)}) if daily_deal.pay_using?(:travelsavers)
      hash
    end
  end

end
