class Syndication::RequestParameters
    
  def self.collect(request)
    parameters = HashWithIndifferentAccess.new
    unless request.params[:reset].present?
      parameters = HashWithIndifferentAccess.new
      request.params.each_pair do |key, value| 
        if [:search_request, :sort, :page, :from_view, :status, :c, :publisher_id].include?(key.to_sym)
          parameters[key.to_sym] = value
        end
      end
    end
    parameters
  end

end