module Syndication::DealsHelper
  
  def list?
    action_name == 'list'
  end
  
  def grid?
    action_name == 'grid'
  end
  
  def calendar?
    action_name == 'calendar'
  end
  
  def map?
    action_name == 'map'
  end
  
  def show?
    action_name == 'show'
  end
  
  def show_key?
    if controller_name == "deals"
      list? || grid? || calendar? || map? || show?
    else
      false
    end
  end
  
  def syndication_site_navigation(context, publisher = nil)
    url = url_for_site_navigation_context(context)
    url << "?publisher_id=" << publisher.to_param if publisher.present?
    clazz = current_page_for_site_navigation?(context) ? "current" : ""
    content_tag(:li, :class => clazz) do
      link_to( t("#{context}"), url )
    end
  end
  
  def syndication_view_by_menu_item(label, href)
    context = label.downcase
    clazz   = ""
    clazz   += "current" if action_name == context
    content_tag(:li, :class => clazz) do
      link_to( label, href, :id => "#{context}_link" )
    end
  end

  def syndication_grid_view_path(request_parmeters = nil)
    request_parmeters[:page] = 1 unless request_parmeters.nil?
    grid_syndication_deals_path(request_parmeters)
  end

  def syndication_list_view_path(request_parmeters = nil)
    request_parmeters[:page] = '1' unless request_parmeters.nil?
    list_syndication_deals_path(request_parmeters)
  end

  def syndication_map_view_path(request_parmeters = nil)
    request_parmeters[:page] = '1' unless request_parmeters.nil?
    map_syndication_deals_path(request_parmeters)
  end
  
  def syndication_calendar_view_path(request_parmeters = nil)
    request_parmeters[:page] = '1' unless request_parmeters.nil?
    calendar_syndication_deals_path(request_parmeters)
  end
  
  def url_for_syndication_status_label_search(status = nil)
    request_parameters = collect_request_parameters
    request_parameters[:page] = '1' if page_parameter.present?
    request_parameters[:status] = status
    if list?
      list_syndication_deals_path(request_parameters)
    elsif grid?
      grid_syndication_deals_path(request_parameters)
    elsif calendar?
      calendar_syndication_deals_path(request_parameters)
    elsif map?
      map_syndication_deals_path(request_parameters)
    else
      list_syndication_deals_path(request_parameters)
    end
  end
  
  def url_for_site_navigation_context(context, options = {})
    existing_parameters = collect_request_parameters
    from_view = existing_parameters[:from_view]
    
    opts = {:include_params => false}.merge!(options)
    request_parameters = opts[:include_params] ? existing_parameters : HashWithIndifferentAccess.new
    
    case context.to_sym
      when :browse_deals
        if from_view == ''
          list_syndication_deals_path(request_parameters)
        elsif from_view == 'grid'
          grid_syndication_deals_path(request_parameters)
        elsif from_view == 'calendar'
          calendar_syndication_deals_path(request_parameters)
        elsif from_view == 'map'
          map_syndication_deals_path(request_parameters)
        else
          list_syndication_deals_path(request_parameters)
        end
      when :my_account
        edit_syndication_user_path(current_user.id, request_parameters)
      when :logout
        syndication_logout_path
      end
  end
  
  def current_page_for_site_navigation?(context)
    if %w(list grid show calendar map).include?(action_name)
      context == :browse_deals
    else
      context == :my_account
    end
  end
  
  def syndication_show_deal_path(deal, options = {})
    request_parameters = collect_request_parameters
    if list?
      request_parameters[:from_view] = 'list'
    elsif grid?
      request_parameters[:from_view] = 'grid'
    elsif calendar?
      request_parameters[:from_view] = 'calendar'
    elsif map?
      request_parameters[:from_view] = 'map'
    else
      request_parameters[:from_view] = 'list'
    end
    request_parameters.merge!(options) if options
    syndication_deal_path(deal, request_parameters)
  end
  
  def sort_options
    {'Date: Ascending' => Syndication::SearchRequest::Sort::START_DATE_ASCENDING, 
     'Date: Descending' => Syndication::SearchRequest::Sort::START_DATE_DESCENDING, 
     'Price: Low to High' => Syndication::SearchRequest::Sort::PRICE_ASCENDING, 
     'Price: High to Low' => Syndication::SearchRequest::Sort::PRICE_DESCENDING}.sort
  end
  
  def syndication_marker_label_from_position(position)
    position.chr # TODO: need to handle the case were position is greater than 122, which represents z
  end
  
  def collect_request_parameters
    Syndication::RequestParameters.collect(request)
  end
  
  def page_parameter
    request.params[:page]
  end
  
  def render_syndication_results_from_search_response(search_response)
    return "" unless search_response && search_response.deals
    total_entries = search_response.deals.total_entries
    current_page  = search_response.deals.current_page
    page_size     = search_response.deals.per_page
    start_index   = 1
    end_index     = page_size
    
    if (current_page > 1) 
      start_index = (current_page-1)*page_size + 1
      end_index   = start_index + page_size - 1
    end
    if (total_entries < end_index) 
      end_index = total_entries
    end
    
    "<span class='the_count'>#{start_index} - #{end_index}</span> of #{pluralize(total_entries, "Offer")}".html_safe
  end
end
