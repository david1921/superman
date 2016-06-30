# Cross-controller Category logic
module Categories

  # Not simply all of the Categories' subcategories. All of the subcategories that match the search scope.
  def subcategories
    assign_categories
    assign_search_params
    # Local.com passes us their "SiteID" which correlates to Publisher#label
    if request.host[/^locm./]
      @publisher = Publisher.find_by_label(params[:publisher_id])
    else
      @publisher = Publisher.find(params[:publisher_id])
    end
    @publisher_id = params[:publisher_id]

    # No auto-coercion with JS 'with' param
    @disclosed = params[:disclosed] == "true"

    # Don't do expensive search when just closing the subcategories
    if !@disclosed
      offers = Offer.find_all_for_publisher(
        :publisher => @publisher, 
        :categories => @categories,
        :text => params[:text], 
        :postal_code => params[:postal_code],
        :radius => params[:radius]
      )
      assign_subcategories(offers, @publisher, @category)      
    end
    
    if @publisher.theme == "withtheme"
      render with_theme(:layout => false, :template => "offers/subcategories" ) and return
    end
    
  end
  
  private

  def assign_subcategories_based_on_search_request(search_request)
    category_search_request = search_request.dup
    category_search_request.categories = [ @category.parent ]
    sub_category_offers = Offer.find_all_for_publisher(category_search_request)
    assign_subcategories sub_category_offers, @publisher, @category.parent
  end

  def assign_categories
    self.class.benchmark "Categories#assign_categories" do
      if params[:category_id].present? 
        @categories = Category.find(params[:category_id])
      elsif @category.present?
        @categories = [@category]
      end
      @categories = Array.wrap(@categories)
      if @categories.size == 1
        @category = @categories.first
      end
    end
  end

  def assign_subcategories(offers, publisher, category)
    self.class.benchmark "Categories#assign_subcategories" do
      if category
        @subcategories = Offer.select_subcategories(publisher, offers, category)
      else
        @subcategories = []
      end
    end
  end
end
