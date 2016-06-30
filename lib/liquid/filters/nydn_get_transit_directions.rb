module Liquid
  module Filters
    module NydnGetTransitDirections
      def nydn_get_transit_directions(advertiser)
        hopstop_url = "http://hopstop.nydailynews.com/?cb3004&city2=#{CGI.escape(advertiser.store.city)}&address2=#{CGI.escape(advertiser.store.address_line_1)}&mode=s&city1=New%20York"
        %Q{<a href="#{hopstop_url}" target="_blank"><img src="/themes/nydailynews/img/get_transit_directions_btn.png" class="get_directions" border="0"></a>}
      end
    end
  end
end