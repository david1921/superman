module ReportsHelper
  
  def nav_link(current_page, page, title, href)
    if current_page == page
      raw "<strong>#{title}</strong>"
    else
      link_to(title, href)
    end
  end
    
end
