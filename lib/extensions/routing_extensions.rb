module ActionController::Routing  

  class RouteSet
    def extract_request_environment(request)
      { :method => request.method, :host => request.host }
    end
  end
  
  class Route
  
    def recognition_conditions_with_host_conditions
     result = recognition_conditions_without_host_conditions
     result << "conditions[:host].include?(env[:host])" if conditions[:host]
     result
    end 
    
    alias_method_chain :recognition_conditions, :host_conditions
    
  end
  
  class RouteSet #:nodoc:
  
    class Mapper #:nodoc:
      
      #
      # Generates an SEO friendly urls for the given publication.
      #
      # Options:
      #   path_prefix - this is used as a prefix, such as city name. (optional)
      #   publisher_label - this is used to look up the publisher
      #   host - the host to listen for the seo friendly requests.
      #   
      # Routes that get generated, if a path_prefix is present.
      #
      # /:path_prefix/deals       - this is the main offers page
      # /:path_prefix/deals/:path - this is the category page
      # /:path_prefix/businesses  - this is the business/coupon directory listing
      # /:path_prefix/map         - this is the map view
      # /:path_prefix/:advertiser - this is the advertiser look by permalink
      #
      # Examples,
      #
      # map.seo_friendly :path_prefix => 'san-francisco', :host => 'coupons.sfweekly.com', :publisher_label => 'sfweekly'
      #
      # would generate the following routes:
      #
      # /san-francisco/deals
      # /san-francisco/deals/:path
      # /san-francisco/businesses
      # /san-francisco/map
      # /san-francisco/:advertiser
      # 
      # it would be mapped to the coupons.sfweekly.com host and would use 'sfweekly' to look up the publisher.      
      def seo_friendly(*args)
        options = args.extract_options!
        
        publisher_label = options.delete(:publisher_label)
        raise ArgumentError, "publisher label is required for seo friendly route" if publisher_label.blank?
        
        host            = options.delete(:host)    
        raise ArgumentError, "host is required for seo friendly route for: #{publisher_label}" if host.blank?
        
        options.merge!( :conditions => {:host => host} )
        with_options( options ) do |seo|
          seo.send("#{publisher_label}_seo_deals", 'deals.:format/*path', :controller => "offers", :action => "seo_friendly_public_index", :publisher_label => publisher_label )  
          seo.send("#{publisher_label}_seo_businesses", 'businesses.:format/*path', :controller => "advertisers", :action => "seo_friendly_public_index", :publisher_label => publisher_label )
          seo.send("#{publisher_label}_seo_map", 'map.:format/*path', :controller => "advertisers", :action => "seo_friendly_public_index", :publisher_label => publisher_label, :with_map => true)
          seo.send("#{publisher_label}_seo_advertiser", ':advertiser_label', :controller => "offers", :action => "seo_friendly_public_index", :publisher_label => publisher_label )
        end
      end 
      
      # Generates an SEO friendly url for the publishers deal of the day
      #
      # Options:
      #   publisher_label - the publisher's label, used to lookup the publisher
      #   host            - the host to listen on
      #
      # Examples:
      #
      #  map.seo_friendly_deal :host => 'houston.bigcity.com', :publisher_label => "houstonpress"
      #
      def seo_friendly_deal(*args)
        options = args.extract_options!
        
        publisher_label = options.delete(:publisher_label)
        raise ArgumentError, "publisher label is required for seo friendly route" if publisher_label.blank?
                                                                                                             
        host            = options.delete(:host)    
        raise ArgumentError, "host is required for seo friendly route for: #{publisher_label}" if host.blank?                
                
        options.merge!( :conditions => {:host => host} ) 
        with_options( options ) do |seo|
          sanitized_label = publisher_label.gsub(/\-/, "_").gsub(/\W/, "")
          seo.send("#{sanitized_label}_seo_daily_deal_faq", "/faqs", :controller => "daily_deals", :action => "seo_friendly_faqs", :publisher_label => publisher_label )
          seo.send("#{sanitized_label}_seo_daily_deal", "/", :controller => "publishers", :action => "seo_friendly_deal_of_the_day", :publisher_label => publisher_label )
        end
        
      end
      
      # 
      # Generates a route to handle routing the root path to the new email subscriber
      # signup page.
      #
      # Example, 
      #
      # map.subscriber_signup_as_root :host => "www.udailydeal.com", :publisher_label => "udailydeal"
      #
      # NOTE, this route definition needs to appear before the map.root definition. 
      def subscriber_signup_as_root(*args)
        options = args.extract_options!
        
        publisher_label = options.delete(:publisher_label)
        raise ArgumentError, "publisher label is required for seo friendly route" if publisher_label.blank?
        
        host            = options.delete(:host)    
        raise ArgumentError, "host is required for seo friendly route for: #{publisher_label}" if host.blank?
                
        options.merge!( :conditions => {:host => host} )
        with_options( options ) do |subscriber|
          subscriber.send("#{publisher_label}_subscriber_signup", '/', :controller => 'subscribers', :action => 'new', :publisher_label => publisher_label)
        end
        
      end
      
    end

  end
end