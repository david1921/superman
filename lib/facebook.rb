module Facebook
  module Tagger
   include ::ActionView::Helpers::TagHelper
   VALID_OPEN_GRAPH_TYPES = %w{activity sport activity sport cause sports_league sports_team band government non_profit school university actor athlete author director musician politician public_figure city country landmark state_province album book drink food game product song movie tv_show blog website article}
    def title(content)
      meta_tag("og:title", content)
    end
    def type(content)
      
      meta_tag("og:type", content) if VALID_OPEN_GRAPH_TYPES.index(content)
    end
    def url(canonical_url)
      meta_tag("og:url", canonical_url)
    end
    def image(canonical_url_to_image)
      meta_tag("og:image", canonical_url_to_image)
    end
    def site_name(content)
      meta_tag("og:site_name", content )
    end
    def description(content)
      meta_tag("og:description", content)
    end
    def admins(user_ids)
      meta_tag("fb:admins", user_ids)
    end
    def app_id(facebook_application_id)
      meta_tag("fb:app_id", facebook_application_id)
    end
    #todo
    def configure
      @tag_stack = self.tap { yield }
    end
    protected
    def meta_tag(property, content)
      tag( "meta", {'property' => property.to_s, 'content' => content.to_s})
    end
  end
  module UI
    include ::ActionView::Helpers::TagHelper
    def init_fb_sdk_block(app_id = nil)
      return if !app_id.present?
      output = <<-__END__
       <div id="fb-root"></div>
        <script src="http://connect.facebook.net/en_US/all.js"></script>
        <script>
          FB.init({ appId  : #{app_id}, status : true, cookie : true, xfbml: true, 
            channelURL : 'http://#{request.host_with_port}/channel.html', oauth  : true });
        </script>
        __END__
      output
    end    
    def like_button(page_url, options = {:send => false})
      options["href"] = page_url
      xfbml_tag("like", options)
      #tag("fb:like", {, 'send' => options[:send]})
    end
    def login_button(options = {})
      xfbml_tag("login-button", options)
    end
    protected
    def xfbml_tag(tag, options)
      tag("fb:#{tag}", options, true)
    end
  end
  module Application
  # See facebook_app.rb
  end
  module Authentication
  # See facebook_auth.rb
  end
  module Channel
    module ControllerActions
      def channel
        expires_in 1.year, :public => true, 'max-stale' => 0
        render :inline => '<script src="http://connect.facebook.net/en_US/all.js"></script>'
      end
    end
  end
end