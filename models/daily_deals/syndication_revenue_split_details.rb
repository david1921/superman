module DailyDeals
  module SyndicationRevenueSplitDetails
    
    def details
      case revenue_split_type
        when 'gross'
          return "[Gross: Source #{source_gross_percentage}% Merchant #{merchant_gross_percentage}% Distributor #{distributor_gross_percentage}%]"
        when 'net'
          return "Merchant #{merchant_net_percentage}% of Net [Source #{source_net_percentage_of_remaining}% Distributor #{distributor_net_percentage_of_remaining}% of Remainder]"
      end
    end
    
  end
end