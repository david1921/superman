module Api2
  module WebCouponsRequest
    class Index < ActiveRecordWithoutTable
      include Api2::ErrorAttribute
      
      belongs_to :publisher
      column :timestamp_min, :datetime
      column :timestamp_max, :datetime

      def initialize(attributes=nil)
        super
        self.timestamp_max = Time.zone.now - 10.seconds
      end
      
      def offers(options = {})
        timestamp_min ? publisher.offers.updated_between(timestamp_min, timestamp_max) : publisher.offers.updated_before(timestamp_max)
      end
    end

    class SyndicatedIndex < ActiveRecordWithoutTable
      include Api2::ErrorAttribute

      column :timestamp_min, :datetime
      column :timestamp_max, :datetime

      def initialize(attributes=nil)
        super
        self.timestamp_max = Time.zone.now - 10.seconds
      end

      def offers(options = {})
        offers = Offer.syndicated
        limit, offset = limit_and_offset_for(options[:page], options[:per_page])
        if timestamp_min
          offers.updated_between(timestamp_min, timestamp_max).all(:order => "updated_at ASC, id ASC", :limit => limit, :offset => offset)
        else
          offers.updated_before(timestamp_max).all(:order => "updated_at ASC, id ASC", :limit => limit, :offset => offset)
        end
      end
      
      protected
      
      def limit_and_offset_for(page, per_page)
        limit = if per_page.present?
          per_page.to_i
        else
          page.present? ? 500 : nil
        end
        offset = page.present? ? (page.to_i - 1) * limit : nil

        [limit, offset]
      end
      
    end
    
    class Show < ActiveRecordWithoutTable
      include Api2::ErrorAttribute
      
      belongs_to :user
      
      validates_presence_of :user
      validate :have_ids

      def initialize(attrs={})
        super
        self.id = attrs[:id]
      end
      
      def id=(value)
        super
        @ids = value.to_s.split(",").select(&:present?)
      end
      
      def offers(options = {})
        Offer.manageable_by(user).find(@ids, :include => :publisher)
      end
      
      private
      
      def have_ids
        @ids ||= []
        errors.add(:id, "%{attribute} must be present") if @ids.empty?
      end
    end

    class Categories < ActiveRecordWithoutTable
      include Api2::ErrorAttribute

      belongs_to :publisher
      
      def categories_to_xml(markup, postfix=nil)
        categories = publisher.placed_offers.map(&:categories).flatten.uniq
        markup.categories do
          categories.group_by(&:parent).tap do |hash|
            if hash.has_key?(nil)
              hash[nil].each do |parent|
                markup.category(:id => "#{parent.id}#{postfix}") do
                  markup.name(parent.name)
                  if (children = hash[parent])
                    markup.categories do
                      children.each do |child|
                        markup.category(:id => "#{child.id}#{postfix}") do
                          markup.name(child.name)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
