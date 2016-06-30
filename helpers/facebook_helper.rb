module FacebookHelper

  def facebook_configured?(publisher)
    FacebookApp.facebook_configured?(publisher)
  end

  def facebook_app_id(publisher)
    FacebookApp.facebook_app_id(publisher)    
  end
  
  def facebook_api_key(publisher)
    FacebookApp.facebook_api_key(publisher)
  end

  def facebook_page_url(publisher)
    publisher.facebook_page_url || publisher.publishing_group.facebook_page_url
  end

  def facebook_comments_div(daily_deal, width, options = {})
    publisher = daily_deal.publisher
    options = {
        :numposts => 10,
        :publish_feed => true
    }.merge(options)
    
    daily_deal_url = if daily_deal.respond_to?(:url)
      daily_deal.url
    else
      market_aware_daily_deal_url(daily_deal, params)
    end
    if facebook_app_id(publisher)
      %Q{
        <div id="fb-root" class="facebook_comments"></div><script src="http://connect.facebook.net/en_US/all.js#appId=#{facebook_app_id(publisher)}&amp;xfbml=1"></script><fb:comments numposts="#{options[:numposts]}" href="#{daily_deal_url}" css="http://#{publisher.daily_deal_host}/stylesheets/facebook_comments_box.css" width="#{width}" publish_feed="#{options[:publish_feed]}"></fb:comments>
      }.html_safe
    else
      %Q{
        <div id="facebook_comments">
          <p> no facebook comments:  no app id configured </p>
        </div>
      }.html_safe
    end
  end

  def facebook_like_button_iframe(daily_deal, width, height, options = {})
    raise "please implement!"
  end

  def facebook_like_box_iframe(publisher, width, height, options = {})
    raise "please implement!"
  end

end
