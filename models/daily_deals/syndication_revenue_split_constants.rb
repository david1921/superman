module DailyDeals
  module SyndicationRevenueSplitConstants
    
    SYNDICATION_REVENUE_SPLIT_TYPE = {'Net' => 'net', 'Gross' => 'gross'}
    SYNDICATION_REVENUE_SPLIT_TYPE_INCLUSION_MESSAGE = "%{attribute} must be #{SYNDICATION_REVENUE_SPLIT_TYPE.keys.to_sentence(:last_word_connector => ' or ', :two_words_connector => ' or ')}."
    
    GROSS_REVENUE_SPLIT_ATTRIBUTES = [:source_gross_percentage, 
                                      :merchant_gross_percentage, 
                                      :distributor_gross_percentage, 
                                      :aa_gross_percentage]
    GROSS_REVENUE_SPLIT_SUM_MESSAGE = "The sum of the gross revenue split should be 100%."
    NET_REVENUE_SPLIT_REMAINING_ATTRIBUTES = [:source_net_percentage_of_remaining,
                                              :distributor_net_percentage_of_remaining,
                                              :aa_net_percentage_of_remaining]
    NET_REVENUE_SPLIT_REMAINING_SUM_MESSAGE = "The sum of the net revenue split remaining values should be 100%."
    
  end
end