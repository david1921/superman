module PaginationHelper
  DEFAULT_PAGE_SIZE = 4

  # page param is 1-based
  def page_size_from_param(page_size, default = nil)
    if page_size.present? && page_size.to_i > 0
      page_size.to_i
    else
      default || DEFAULT_PAGE_SIZE
    end
  end  
  
  # returns a hash of basic parameters used in pagination,
  # and form submission to persist some of the parameters
  # between paging and browsing.
  def basic_params_for_pagination
    @pagination_params ||= {
      :background_color => @background_color,
      :foreground_color => @foreground_color,
      :city             => @city,       
      :state            => @state,      
      :page_size        => @page_size,       
      :iframe_height    => @iframe_height,
      :iframe_width     => @iframe_width,
      :layout           => @layout,
      :sort             => @sort    
    }
  end
  
  def pagination_link_params(page)
    basic_params_for_pagination.
      merge( search_params_for_pagination ).
      merge( category_params_for_pagination ).
      merge(:page => page)
  end 
  
  def page_size_params_for_pagination
    basic_params_for_pagination.
      merge( search_params_for_pagination ).
      merge( category_params_for_pagination )    
  end 
  
  def params_for_switching_between_list_and_grid_view
    basic_params_for_pagination.
      merge( search_params_for_pagination ).
      merge( category_params_for_pagination ).except(:page_size, :sort, :page, :order).merge(:category => @category)
  end
  
  def search_params_for_pagination 
    {
      :order            => @order,  
      :postal_code      => @postal_code, 
      :radius           => @radius, 
      :text             => @text
    }
  end
  
  def category_params_for_pagination
    if @category.present?
      { :category_id => @category.id }
    else      
      categories = @categories || []
      categories.present? ? { :category_id => categories.collect(&:id).join(',') } : {}
    end
  end

  class RangeFormatter
    def initialize(page_count, page_index)
      page_count = 1 if page_count < 1
      page_index = 1 if page_index < 1
      page_index = page_count if page_index > page_count
      @page_count = page_count
      @page_index = page_index
      @range_min = [1, [@page_index - 3, @page_count - 5].min].max
      @range_max = [@page_count, @range_min + 5].min
    end
    
    def index_range
      @range_min .. @range_max
    end
    
    def text_for(index)
      if  index < @range_min
        index = @range_min.to_s
      elsif index > @range_max
        index = @range_max.to_s
      else
        index.to_s
      end
    end
  end
end
