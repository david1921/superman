require File.dirname(__FILE__) + "/../test_helper"

class SearchRequestTest < ActiveSupport::TestCase

  def test_new_with_empty_attributes
    attributes = {}
    assert_raise RuntimeError do
      search_request = SearchRequest.new(attributes)
    end
  end  
  
  def test_new_with_basic_attributes
    publisher       = publishers(:my_space)       
    attributes      = {:publisher => publisher}
    search_request  = SearchRequest.new( attributes )
    assert_equal publisher, search_request.publisher
  end
  
  def test_new_with_text_that_is_not_a_postal_code
    publisher       = publishers(:my_space)                       
    
    attributes      = {:publisher => publisher, :text => "Health"}
    search_request  = SearchRequest.new( attributes )
    
    assert_equal "Health",  search_request.text
    assert_nil   search_request.postal_code
  end
  
  def test_new_with_text_that_is_a_postal_code
    postal_code     = "97206"
    publisher       = publishers(:my_space)
    
    attributes      = {:publisher => publisher, :text => postal_code}
    search_request  = SearchRequest.new( attributes )
    
    assert_nil   search_request.text
    assert_equal postal_code,  search_request.postal_code
  end
  
  def test_new_with_postal_code_and_default_offer_search_distance_set_for_publisher
    publisher       = publishers(:my_space)
    publisher.update_attribute( :default_offer_search_distance, "25" )
    
    attributes      = {:publisher => publisher, :postal_code => "97206"}
    search_request  = SearchRequest.new( attributes )
    
    assert_equal  "97206",    search_request.postal_code
    assert_equal  25,       search_request.radius
  end
  
  def test_new_with_default_offer_search_postal_code_set_for_publisher
    publisher       = publishers(:my_space)
    publisher.update_attribute( :default_offer_search_postal_code, "97206" )
    
    attributes      = {:publisher => publisher}
    search_request  = SearchRequest.new( attributes )
    
    assert_equal  "97206", search_request.postal_code    
  end
  
  def test_new_with_default_offer_search_postal_code_set_for_publisher_and_different_postal_code
    publisher       = publishers(:my_space)
    publisher.update_attribute( :default_offer_search_postal_code, "97206" )
    
    attributes      = {:publisher => publisher, :postal_code => "97217"}
    search_request  = SearchRequest.new( attributes )
    
    assert_equal  "97217", search_request.postal_code        
  end
  
  def test_new_with_default_offer_search_postal_code_set_for_publisher_and_search_text_provided
    publisher       = publishers(:my_space)
    publisher.update_attribute( :default_offer_search_postal_code, "97206" )
    
    attributes      = {:publisher => publisher, :text => "Health"}
    search_request  = SearchRequest.new( attributes )           
    
    assert_equal "Health", search_request.text
    assert_nil   search_request.postal_code
  end 
  
  def test_new_with_default_offer_search_postal_code_set_for_publisher_and_search_text_is_another_postal_code
    publisher       = publishers(:my_space)
    publisher.update_attribute( :default_offer_search_postal_code, "97206" )
    
    attributes      = {:publisher => publisher, :text => "97217"}
    search_request  = SearchRequest.new( attributes )
    
    assert_equal  "97217", search_request.postal_code    
  end 
  
  def test_with_featured_set_to_false
    publisher       = publishers(:my_space)
    publisher.update_attribute( :default_offer_search_postal_code, "97206" )
    
    attributes      = {:publisher => publisher, :text => "97217", :featured => 'false'}
    search_request  = SearchRequest.new( attributes )
    
    assert !search_request.featured?
  end
  
  def test_with_featured_set_to_true
    publisher       = publishers(:my_space)
    publisher.update_attribute( :default_offer_search_postal_code, "97206" )
    
    attributes      = {:publisher => publisher, :text => "97217", :featured => 'true'}
    search_request  = SearchRequest.new( attributes )
    
    assert search_request.featured?
  end  

end