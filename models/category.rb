class Category < ActiveRecord::Base
  has_and_belongs_to_many :offers
  acts_as_tree
  
  validates_presence_of :name
  validates_immutability_of :parent_id
  validate :limit_depth       
  
  before_create :generate_label_from_name

  named_scope :allowed_by_publishing_group, lambda {|publishing_group|
    {:conditions => ["categories.id IN (
                         SELECT category_id
                         FROM categories_publishing_groups
                         WHERE publishing_group_id = ?)",
                         publishing_group.id]}}
  
  alias :subcategories :children
  
  def self.valid_objects_from_names(text)
    Set.new.tap do |set|
      text.split(",").each do |chunk|
        if chunk.present?
          parent = nil
          chunk.split(":").each do |name|
            if name.present?
              category   = set.detect { |c| name.strip == c.name && c.parent == parent }
              category ||= Category.find_by_name_and_parent_id(name.strip, parent.try(:id)) unless parent.try(:new_record?)
              category ||= Category.new(:name => name.strip, :parent => parent)
              if category.invalid?
                raise category.errors.full_messages.join(", ")
              end
              set << (parent = category)
            end
          end
        end
      end
    end
  end

  def self.all_with_offers_count_for_publisher(search_request)
    benchmark "Category#all_with_offers_count_for_publisher" do
      search_request = SearchRequest.create(search_request)    
      logger.debug("Category#all_with_offers_count_for_publisher #{search_request}") if logger.debug?
      
      publisher     = search_request.publisher
      publisher_ids = publisher.search_by_publishing_group? ? publisher.publishing_group.publishers.collect(&:id) : [publisher.id]

      sql =<<-EOF
        (show_on IS NULL OR :date >= show_on) AND (expires_on IS NULL OR :date <= expires_on) AND offers.deleted_at IS NULL AND placements.publisher_id in (:publisher_ids)
      EOF
      basic_conditions = sanitize_sql_for_conditions([sql, { :date => Time.zone.now.to_date, :publisher_ids => publisher_ids }])

      options = if search_request.postal_code.present?
        { :joins => { :offers => [:placements, { :advertiser => :stores }] }, 
          :conditions => [ "#{basic_conditions} AND SUBSTR(stores.zip, 1, 5) IN (?)", 
                           ZipCode.zips_near_zip_and_radius(search_request.postal_code, search_request.radius) ]
        }
      else
        { :joins => { :offers => :placements }, 
          :conditions => basic_conditions
        }
      end
      options.merge!({
        :select => 'categories.id, categories.name, categories.parent_id, categories.label, COUNT(*) AS offers_count', 
        :include => :children,
        :group => 'categories.id'
      })
      find(:all, options).each do |category|
        category.offers_count = category.offers_count.to_i
      end.select { |category| category.parent.nil? }
    end
  end 
  
  def self.find_publisher_category_based_on_category_label( publisher, category_label )
    return nil if publisher.nil? || category_label.blank?
    find(:first, { :joins => {:offers => :placements}, :conditions => ["placements.publisher_id = :publisher_id and categories.label = :category_label AND offers.showable AND (offers.show_on IS NULL OR :date >= offers.show_on) AND (offers.expires_on IS NULL OR :date <= offers.expires_on)", {:publisher_id => publisher.id, :category_label => category_label, :date => Time.zone.now}]})
  end  
  
  def self.find_by_path(path)
    if path && path.is_a?(Array)
      path    = path.clone
      leaf    = path.pop
      parent  = path.pop
      return nil if leaf.blank? and parent.blank?
                                         
      parent_category = parent.blank? ? nil : Category.find_by_label(parent) 
      unless parent_category.nil?
        parent_category.children.find_by_label(leaf)
      else
        Category.find_by_label(leaf)
      end
    end
  end
  
  def limit_depth
    if (parent && parent.parent) || (parent && children.present?)
      errors.add_to_base("Category can only be two levels deep")
    end
  end
  
  def downcase_name
    name.try :downcase
  end
  
  def full_name
    parent ? "#{parent.name}: #{name}" : name.to_s
  end
  
  def to_s
    "#<Category #{id} #{parent_id} #{name}>"
  end 
  
  def generate_label_from_name
    unless name.blank?
      self.label = name.gsub("'", "").parameterize.to_s
    end
  end      
  
  def generate_label_from_name!
    generate_label_from_name
    save
  end
   
  def to_liquid
    Drop::Category.new(self)
  end
  
end
