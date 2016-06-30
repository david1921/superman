xml.instruct! :xml, :version => '1.0'

timestamps = (@request.timestamp_min ? { :timestamp_min => @request.timestamp_min.utc.to_formatted_s(:iso8601) } : {}).merge!({
  :timestamp_max => @request.timestamp_max.utc.to_formatted_s(:iso8601)
})

xml.web_coupons(timestamps) do
  @request.offers(:page => params[:page], :per_page => params[:per_page]).each do |offer|
    xml.web_coupon(:id => "#{offer.id}-offer") do
      xml.created_at(offer.created_at.utc.to_formatted_s(:iso8601))
      xml.updated_at(offer.self_or_advertiser_or_store_last_updated_at.utc.to_formatted_s(:iso8601))
      if offer.deleted?
        xml.deleted_at(offer.deleted_at.utc.to_formatted_s(:iso8601))
      else
        xml.link(:href => api2_web_coupons_url(:id => offer.to_param))
      end
    end
  end
end
