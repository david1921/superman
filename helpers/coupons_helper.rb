module CouponsHelper
  def public_index_notice(publisher)
    if Rails.env =~ /^demo/
      content = "Sample coupons &mdash; not redeemable in store".html_safe
    elsif "San Diego News Network" == publisher.name
      content = "Business Owners: Try two months of <strong>FREE</strong> coupon advertising on this page!
                 Contact #{mail_to("sales@analoganalytics.com", nil, :subject => "Coupon advertising")}.
                 Offer limited to the first 25 new advertisers.".html_safe
    end
    (defined?(content) && content.present? ? content_tag(:div, content, :id => "notice") : "").html_safe
  end

  # Consider a CouponLayout class to encapsulate related logic.
  # Is a hard error really what we want?
  def iframe_height(page_size, height = nil)
    return height.to_i if height.present? && height.to_i > 0

    case @publisher.theme
    when "standard", "sdcitybeat", "withtheme"
      292 + (page_size / 2).round * 304
    when "simple", "sdreader", "narrow"
      142 + (page_size / 2).round * 304
    when "enhanced"
      146 + page_size * 336
    else
      raise "Unknown layout '#{@publisher.theme}'"
    end
  end

  def iframe_width(width = nil)
    return width.to_i if width.present? && width.to_i > 0

    case @publisher.theme
    when "simple", "enhanced", "sdreader", "standard", "sdcitybeat", "withtheme"
      936
    when "narrow"
      625
    else
      raise "Unknown layout '#{@publisher.theme}'"
    end
  end
  
  def link_to_map(offer)
    if offer.publisher.link_to_map? && (map_url = offer.advertiser.map_url).present?
      link_to("Map", map_url, :target => "_blank")
    end
  end
  
  def map_image_url_for(offer, size = "640x250", multi_loc = false)
    stores = offer.advertiser.stores
    if multi_loc && stores.present? && stores.length > 1
      escaped_addresses = stores.map do |s|
        CGI.escape("#{s.address_line_1}, #{s.city}, #{s.state} #{s.zip}")
      end
      "http://maps.google.com/maps/api/staticmap?size=#{size}&markers=size:small|#{escaped_addresses.join('|')}&sensor=false"
    else
      store = offer.advertiser.store
      if store
        escaped_address = CGI.escape("#{store.address_line_1}, #{store.city}, #{store.state} #{store.zip}")
        "http://maps.google.com/maps/api/staticmap?size=#{size}&center=#{escaped_address}&markers=size:small|#{escaped_address}&key=ABQIAAAAzObGV3GscSCtMupcN2Jm-RSSjhI9lG3KGwm-Keiwru5ERTctHhTXe3LfYrff_rQT8DZgaQB6AthF0A&sensor=false"
      else
        ""
      end
    end
  end
  
  def url_for_facebook_image(offer)
    if offer.advertiser.logo.file? && offer.advertiser.logo_dimension_valid_for_facebook?
      offer.advertiser.logo :facebook
    elsif offer.offer_image.file?
      offer.offer_image :medium
    elsif offer.photo.file?
      offer.photo :standard
    else
      # missing.png
      offer.advertiser.logo :standard
    end
  end
  
  def advertiser_name(offer)
    advertiser_name = truncate(offer.advertiser_name, :length => 32)
    if offer.publisher.present?
      unless offer.publisher.standard_theme? || offer.publisher.theme == "sdcitybeat"
        advertiser_name = advertiser_name.upcase
      end
      if offer.publisher.link_to_website? && (website_url = offer.website_url).present?
        link_to(h(advertiser_name), website_url, :target => "_blank")
      else
        advertiser_name
      end      
    else
      advertiser_name
    end
  end
  
  def link_to_website?(offer)
    offer.publisher.link_to_website? && offer.website_url.present?
  end
  
  def link_to_website(offer, text = "Website")
    if link_to_website?(offer)
      link_to text, offer.website_url, :target => "_blank"
    end
  end
  
  def link_to_email(offer)
    if offer.publisher.link_to_email? && (email_address = offer.email_address).present?
      mail_to(h(email_address), "Email")
    end
  end  
  
  def offer_phone_number(offer)
    phone_number = offer.publisher.show_phone_number? ? offer.advertiser.phone_number_as_entered : nil
    unless phone_number.blank?
      content_tag(:span, phone_number, :class => 'phone')
    end
  end
  
  def link_to_advanced_search(link_text, publisher, text, postal_code, radius, category, categories, iframe_height, iframe_width, layout)
    link_params = {
      :iframe_height => iframe_height,
      :iframe_width  => iframe_width,
      :layout        => layout,
      :text          => text, 
      :postal_code   => postal_code, 
      :radius        => radius 
    }
    if categories && categories.present?
      if categories.size == 1
        link_params.merge!({ :category_id => category })
      else
        link_params.merge!({ :category_id => categories })
      end
    end
    link_to h(link_text), publisher_home_path(publisher.label, link_params), :target => publisher.advanced_search_link_target
  end
  
  def terms_size(offer)
    case offer.terms_with_expiration.size
    when 220..500
      "very_long"
    when 151..219
      "long"
    else
      "normal"
    end
  end  
 
  def vvm_h1_tag
    h1_content = ""
    if @text.present?
      h1_content =  "You searched for #{truncate(@text, :length => 30)}"
      h1_content += " in #{@postal_code}" if @postal_code.present?
    elsif @postal_code.present?
      h1_content = "ZIP: #{@postal_code}"      
    else
      h1_content = "#{@category.name} Coupons" if @category
      h1_content = "#{@advertiser.name} Coupons" if @advertiser
    end
    h1_content = "Coupons" if h1_content.blank?
    content_tag(:h1, h1_content)
  end

  # NOTE: this could probably be re-used for other themes as well
  def breadcrumbs_for_business_directory_theme                         
    breadcrumbs = ""
    if @text.present?
      breadcrumbs = "You searched for #{truncate(@text, :length => 30)}"
      breadcrumbs += " in #{@postal_code}" if @postal_code.present?
    elsif @postal_code.present? 
      breadcrumbs = "ZIP: #{@postal_code}"
    end
    if @category
      if @text.present?
        breadcrumbs += " in "
      else
        options = {
          :category_id => nil,
          :iframe_width   => params[:iframe_width],
          :iframe_height  => params[:iframe_height],
          :layout         => @layout,
          :page_size      => params[:page_size]
        }
        breadcrumbs += link_to( "Coupons: ", options )
      end
      if @category.parent 
        breadcrumbs += "#{link_to( h(@category.parent.name), pagination_link_params(@page).merge!( :category_id => @category.parent.to_param) )}: "
      end
      breadcrumbs += link_to( h(@category.name), pagination_link_params(@page) )
    end
    breadcrumbs = "&nbsp;" if breadcrumbs.blank?
    content_tag( :div, breadcrumbs, :class => 'breadcrumbs' )
  end
  
  def render_grid_list_controls( options = {}, show_label = true )
    active_control = options[:active_control] || :grid
    show_sort_by   = options[:show_sort_by]
    publisher      = options[:publisher]   
    view_map_icon  = options[:view_map_icon]  || "/images/coupons/view-map.png"
    view_grid_icon = options[:view_grid_icon] || "/images/coupons/view-grid.png"
    view_list_icon = options[:view_list_icon] || "/images/coupons/view-list.png"

    view_switch_params = params_for_switching_between_list_and_grid_view
    if show_label
      grid_list_control = "View As: "
    else
      grid_list_control = ""
    end
    grid_list_control += (active_control == :map ? image_tag(view_map_icon, :title => "Map") : ( link_to( image_tag(view_map_icon, :title => "Map"), render_public_advertisers_path( publisher, view_switch_params.merge(:path_for_map => true) ) ) ))
    grid_list_control += "&nbsp;"
    grid_list_control += active_control == :grid ? image_tag(view_grid_icon, :title => "Grid") : ( link_to( image_tag(view_grid_icon, :title => "Grid"), render_public_offers_path( publisher, view_switch_params ) ) )
    grid_list_control += "&nbsp;"
    grid_list_control += active_control == :list ? image_tag(view_list_icon, :title => "List") : ( link_to( image_tag(view_list_icon, :title => "List"), render_public_advertisers_path( publisher, view_switch_params.merge(:skip_map_url_transform => true) ) ) )
    
    grid_list_control += "&nbsp;#{render_sort_by_control( options )}" if show_sort_by 
    
    content_tag( :div, grid_list_control.html_safe, :class => 'view_sort' )
  end  
  
  def render_sort_by_control( options = {} )   
    postal_code = options[:postal_code]
    radius      = options[:radius]
    sort        = options[:sort]
    sort_by_control = "Sort By: "
    sort_by_control += select_tag( "page_sort", options_for_select([ "Name", "Most Recent", (@postal_code.blank? && @radius.blank? ? nil : "Distance")].compact.uniq.sort, @sort), :id => "page_sort_select")
    sort_by_control
  end
  
  # Does this method add any value?
  def offer_photo_image_tag(offer, alt = "photo")
    attachment, style = offer.photo, :standard
    # Transitional code for S3
    attachment_url = attachment.url(style)
    if attachment_url["missing"]
      url = attachment_url
    else
      url = "#{attachment.url(style)}"
    end
    image_tag(url, :src => url, :class => "photo", :id => "offer_#{offer.id}_photo", :alt => alt)
  end
  
  def advertiser_logo_image_tag(advertiser_or_offer, alt = "logo")
    attachment = advertiser_or_offer.is_a?( Advertiser ) ? advertiser_or_offer.logo : advertiser_or_offer.advertiser.logo
    style      = :standard
    publisher  = advertiser_or_offer.publisher
    # Transitional code for S3
    attachment_url = attachment.url(style)
    if attachment_url["missing"]
      url = attachment_url
    else
      url = "#{attachment.url(style)}"
    end
    image_tag url, :src => url, :id => "#{advertiser_or_offer.class.to_s.downcase}_#{advertiser_or_offer.id}_logo", :alt => alt
  end
  
  def render_village_voice_page_title( city )
    page_title = t('village_voice_media.page_title.general', :city => city )
    if @category
      page_title = t(
        "village_voice_media.page_title.categories.#{@category.name.parameterize("_")}", 
        :city => city, 
        :default => "#{@category.name.singularize} Coupons – discounts deals and coupons for #{city}"
      )
    elsif @advertiser
      page_title = t("village_voice_media.page_title.advertiser", :name => @advertiser.name)
    end
    page_title
  end
  
  def render_meta_description_for_village_voice_media(location)
    content = t('village_voice_media.meta_description.general', :location => location)
    if @category
      content = t("village_voice_media.meta_description.category", :location => location, :name => @category.name, :singular_name => @category.name.singularize)
    elsif @advertiser
      content = t("village_voice_media.meta_description.advertiser", :name => @advertiser.name)
    end
    "<meta name='description' content='#{content}'>".html_safe
  end
  

end
