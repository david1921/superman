namespace :oneoff do
  
  namespace :fundogo do
    
    task :setup_publisher_categories do
      publisher = Publisher.find_by_label!("fundogo")
      %w(Buy Do Eat Go Help Indulge See).each do |cat_name|
        publisher.daily_deal_categories.create! :name => cat_name
      end
    end
    
  end
  
end