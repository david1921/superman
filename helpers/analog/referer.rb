module Analog
  module Referer
    module Controller
      
      def self.included(base)
        base.send :include, InstanceMethods
      end

      module InstanceMethods

        def set_referer_information
          if request.format.html?
            unless cookies["retain_until"].present? && cookies["retain_until"].to_time > Time.zone.now
              # NOTE: currently this is for Inuvo (kowabunga), and they need a 30 day expiration.
              # if other publications need this, then we should have a days_to_retain_for on publisher.
              session['first_time_visitor'] = true if cookies["retain_until"].blank?
              cookies["retain_until"] = { :value => Time.zone.now + 30.days, :expires => Time.zone.now + 10.years }
            end

            # Setting of the ref cookie was once in the above unless block. It has been decoupled from the retain_until logic
            # until Inuvo (kowabunga) is sure they want it there. Yes, yes, I know...
            cookies["ref"] = { :value => params[:pubid], :expires => Time.zone.now + 10.years } if params[:pubid].present? # pubid is kowabunga specific
            session['src'] = params[:sourceid] if params[:sourceid].present? # sourceid is kowabunga specific
          end
        end
      end
    end
    
    module Helper
    
      def self.included(base)
        base.send :include, InstanceMethods
      end
      
      module InstanceMethods
      
        def link_to_affiliate_url(daily_deal, options = {})
          url = daily_deal.affiliate_url || ""
          kontroller = if respond_to?(:controller) && controller.present?
            controller
          elsif @controller.present?
            @controller
          else
            options[:controller]
          end

          if kontroller
            url.gsub!("%ref%", kontroller.send(:cookies)["ref"] || "")
            url.gsub!("%src%", kontroller.send(:session)["src"] || "")
          end
          # add tracking parameters so third parties can track this link and pay us
          params = {
            "aa_id" => daily_deal.publisher.label + "|" + daily_deal.id.to_s + "|" + daily_deal.uuid
          }
          return url + (url.include?("?") ? "&" : "?") + params.to_query
        end
        
        
      end
      
    end
    
    
  end
end
