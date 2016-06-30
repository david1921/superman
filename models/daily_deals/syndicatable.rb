module DailyDeals
  module Syndicatable
    include DailyDeals::Syndicatable::SynchronizedAttributes

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :include, Report::Syndication
      base.send :include, DailyDeals::Locks
      
      base.class_eval do
        
        belongs_to :source, :class_name => "DailyDeal"
        
        # add source_publisher method that returns nil if there is no source
        delegate :publisher, :listing, :to => :source, :prefix => true, :allow_nil => true
        
        has_many :syndicated_deals, :class_name => "DailyDeal", :foreign_key => "source_id",
                 :conditions => "deleted_at IS NULL",
                 :after_add => :populate_syndicated_deal_attributes_from_source
                  
        before_destroy :destroyable? 
        
        before_validation :set_syndicated_deals_by_publisher_ids
        before_validation :set_syndicated_deals_analytics_category_to_unassigned_if_necessary
        
        validate :source_is_syndicatable
        validate :ensure_locks, :on => :update
        validate :protect_synced_syndicated_deal_attributes
        
        # Disable automatic validation of syndicated_deals so we can add more
        # useful error messages.
        def validate_associated_records_for_syndicated_deals; end
        validate :syndicated_deals_are_valid
        
        validate :in_syndication_network
        
        after_save :save_syndicated_deals

        alias_method :bar_codes_without_syndication, :bar_codes
        alias_method :bar_codes, :bar_codes_with_syndication
        alias_method :distributed?, :syndicated?
        
        #todo: rename to with_source?
        named_scope :syndicated, :conditions => "source_id IS NOT NULL"
        named_scope :not_syndicated, :conditions => "source_id IS NULL"
      end
    end
    
    module InstanceMethods

      def populate_syndicated_deal_attributes_from_source(syndicated_deal)
        merged_attributes = self.attributes.except("cobrand_deal_vouchers").merge({:source_id => syndicated_deal.source_id, :publisher_id => syndicated_deal.publisher_id})
        merged_attributes['bit_ly_url'] = nil
        merged_attributes['affiliate_revenue_share_percentage'] = nil
        merged_attributes['available_for_syndication'] = false
        
        syndicated_deal.send(:attributes=, merged_attributes)

        (@new_syndicated_deals ||= []) << syndicated_deal
      end
      
      def syndicated_deals_are_valid
        syndicated_deals.each do |syndicated_deal|
          unless syndicated_deal.valid?
            errors.add(:base, "Invalid distributed deal: #{syndicated_deal.errors.full_messages.join(', ')}")
          end
        end
      end

      def in_syndication_network
        unless publisher.publishing_group.try(:restrict_syndication_to_publishing_group)
          if syndicated? && available_for_syndication?
            errors.add :base, "A distributed deal cannot be made available for syndication."
          end
          if syndicated? && !source.in_syndication_network?
            errors.add :base, "A deal can only be distributed if its source publisher is in the syndication network."
          end
          if syndicated? && !source.available_for_syndication?
            errors.add :base, "A deal can only be distributed if it's source deal is available for syndication." 
          end
          if available_for_syndication? && !in_syndication_network?
            errors.add :base, "A deal's publisher must be in the syndication network for it to be made available for syndication"
          end
          if source? && !available_for_syndication?
            errors.add :base, "A source deal that is distributed can not be made unavailable for syndication."
          end
        end
      end

      def source_is_syndicatable
        return unless source.present?

        if source.syndicated?
          errors.add(:base, "Distributed deal cannot be distributed.")
        elsif source.publisher_id == publisher_id
          errors.add(:base, "Distributing publisher cannot be the same as the source publisher.") 
        elsif !source.publisher.syndication_allowed_to_publisher?(publisher)
          errors.add(:base, "Deal cannot be distributed by the requested publisher.") 
        elsif source.has_variations? && !publisher.enable_daily_deal_variations
          errors.add(:base, "Deal cannot be distributed unless variations are enabled on the distributing publisher.")
        end
      end
      
      def save_syndicated_deals
        DailyDeal.transaction do
          syndicated_deals.each do | syndicated_deal |
            syndicated_deal.save!
            syndicated_deal.reload
          end
        end

        enqueue_source_deal_photo_copies
      end
      
      def destroyable?
        syndicated_deals.empty?
      end
      
      #todo: rename to has_source?
      def syndicated?
        source.present?
      end
      
      #todo: rename to is_source?
      def source?
        syndicated_deals.count > 0
      end
      
      def sourceable_by_publisher?(_publisher)
        belongs_to_publisher?(_publisher) && !available_for_syndication? && !source.present?
      end
      
      def sourced_by_publisher?(_publisher)
        belongs_to_publisher?(_publisher) && available_for_syndication?
      end
      
      def sourced_by_network?(_publisher)
        !belongs_to_publisher?(_publisher) && 
        available_for_syndication?
      end
      
      def distributed_by_publisher?(_publisher)
        if source.present?
          return belongs_to_publisher?(_publisher) && !available_for_syndication?
        else
          if syndicated_deals.empty?
            return false
          else
            return syndicated_deals.detect {|deal| deal.publisher_id == _publisher.id}.present?
          end
        end
      end
      
      def distributed_by_network?(_publisher)
        if source.present?
          !belongs_to_publisher?(_publisher) && !available_for_syndication?
        else
          !syndicated_deals.empty?
        end
      end
      
      def sourceable?(_publisher)
         belongs_to_publisher?(_publisher) && !available_for_syndication? && !syndicated?
      end
      
      def unsourceable?(_publisher)
         belongs_to_publisher?(_publisher) && available_for_syndication? && syndicated_deals.empty?
      end
      
      def distributable?(_publisher)
        sourced_by_network?(_publisher) && !distributed_by_publisher?(_publisher) && !self.publisher.publishers_excluded_from_distribution.include?(_publisher)
      end
      
      def all_publishers_available_for_syndication(include_publishers_for_syndicated_deals = false, exclude_unlaunched = false)
        not_in_ids = [publisher_id]
        not_in_ids += syndicated_deals.map(&:publisher_id) unless include_publishers_for_syndicated_deals
        
        options = { :include => :publishing_group, :conditions => ["id not in (?)", not_in_ids]}
        
        if publisher.publishing_group.try(:restrict_syndication_to_publishing_group)
          scope = publisher.publishing_group.publishers
        else
          scope = Publisher
        end

        scope = scope.launched if exclude_unlaunched
        scope = scope.in_travelsavers_syndication_network if pay_using?(:travelsavers)
        scope.all(options)
      end
      
      def number_sold(end_date = nil)
        BaseDailyDealPurchase.sum("quantity", :conditions => ["daily_deals.id = ? AND daily_deal_purchases.payment_status != 'pending' #{executed_at_filter(end_date)}", id], :joins => :daily_deal)
      end
      
      def number_refunded(end_date = nil)
        # !!DO NOT REMOVE THE DOUBLE COLONS HERE!!
        ::DailyDealCertificate.count(:conditions => ["daily_deals.id = ? AND daily_deal_purchases.payment_status = 'refunded' AND daily_deal_certificates.status = 'refunded' #{refunded_at_filter(end_date)}", id], :joins => certificate_refunds_joins)
      end
      
      def number_sold_including_syndicated(end_date = nil)
        if source?
          # !!DO NOT REMOVE THE DOUBLE COLONS HERE!!
          sum = ::DailyDealPurchase.sum("quantity", :conditions => ["(daily_deals.id = ? OR daily_deals.source_id = ?) AND daily_deal_purchases.payment_status != 'pending' #{executed_at_filter(end_date)}", id, id], :joins => :daily_deal)
          publisher.try(:pay_using?, :paypal) ? sum + 1 : sum
        elsif syndicated?
          # !!DO NOT REMOVE THE DOUBLE COLONS HERE!!
          sum = ::DailyDealPurchase.sum("quantity", :conditions => ["(daily_deals.id = ? OR daily_deals.id = ? OR daily_deals.source_id = ?) AND daily_deal_purchases.payment_status != 'pending' #{executed_at_filter(end_date)}", id, source.id, source.id], :joins => :daily_deal)
          publisher.try(:pay_using?, :paypal) ? sum + 1 : sum
        else
          sum = number_sold(end_date)
        end
      end
      
      def number_refunded_included_syndicated(end_date = nil)
        if source?
          # !!DO NOT REMOVE THE DOUBLE COLONS HERE!!
          ::DailyDealCertificate.count(:conditions => ["(daily_deals.id = ? OR daily_deals.source_id = ?) AND daily_deal_purchases.payment_status = 'refunded' AND daily_deal_certificates.status = 'refunded' #{refunded_at_filter(end_date)}", id, id], :joins => certificate_refunds_joins)
        elsif syndicated?
          # !!DO NOT REMOVE THE DOUBLE COLONS HERE!!
          ::DailyDealCertificate.count(:conditions => ["(daily_deals.id = ? OR daily_deals.id = ? OR daily_deals.source_id = ?) AND daily_deal_purchases.payment_status = 'refunded' AND daily_deal_certificates.status = 'refunded' #{refunded_at_filter(end_date)}", id, source.id, source.id], :joins => certificate_refunds_joins)
        else
          number_refunded(end_date)
        end
      end
      
      def executed_at_filter(end_date = nil)
        if end_date.present?
          "AND daily_deal_purchases.executed_at <= %s" % connection.quote(end_date)
        else
          ""
        end
      end
      
      def refunded_at_filter(end_date = nil)
        if end_date.present?
          "AND daily_deal_purchases.refunded_at <= %s" % connection.quote(end_date)
        else
          ""
        end
      end
      
      def bar_codes_with_syndication(force_reload = false)
        unless source.present?
          bar_codes_without_syndication(force_reload)
        else
          source.bar_codes_without_syndication(force_reload)
        end
      end
      
      def syndicated_deal_publisher_ids
        syndicated_deals.map(&:publisher).map(&:id)
      end

      def syndicated_deal_publisher_ids=(new_publisher_ids)
        @syndicated_deal_publisher_ids = new_publisher_ids
      end

      private
      
      def belongs_to_publisher?(_publisher)
        _publisher.try(:id) == self.publisher_id
      end

      def source_belongs_to_publisher?(_publisher)
        _publisher.try(:id) == source.try(:publisher_id)
      end

      def set_syndicated_deals_by_publisher_ids
        return if @syndicated_deal_publisher_ids.nil?

        new_publisher_ids = @syndicated_deal_publisher_ids.map(&:to_i).to_set
        old_publisher_ids = syndicated_deal_publisher_ids.to_set

        deleted_publisher_ids = old_publisher_ids - new_publisher_ids
        new_publisher_ids = new_publisher_ids - old_publisher_ids

        deleted_publisher_ids.each do |publisher_id|
          syndicated_deals.find_all_by_publisher_id(publisher_id).each do |syndicated_deal|
            syndicated_deal.mark_as_deleted!
          end
        end

        new_publisher_ids.each do |publisher_id|
          syndicated_deals.build(:publisher_id => publisher_id)
        end
      end

      def set_syndicated_deals_analytics_category_to_unassigned_if_necessary
        # Some deals such as DoubleTake have no analytics category but a lot
        # of publisher require an analytics_category on daily deals.  Christina/Graeme
        # decided to add a new analytics category called "Unassigned" to assign a 
        # placeholder analytics category for these deals.
        return unless syndicated?
        self.analytics_category = DailyDealCategory.analytics.unassigned unless self.analytics_category.present?
      end

      def enqueue_source_deal_photo_copies
        # Should only do this in production, staging or nightly so that tests don't try S3 connection
        if @new_syndicated_deals.present? && (Rails.env.production? || Rails.env.staging? || Rails.env.development?)
          @new_syndicated_deals.each do |syndicated_deal|
            Resque.enqueue(DailyDeals::CopySourceDealPhotos, syndicated_deal.id)
          end
        end
      end
      
      def certificate_refunds_joins
        "INNER JOIN daily_deal_purchases ON daily_deal_certificates.daily_deal_purchase_id = daily_deal_purchases.id INNER JOIN daily_deals ON daily_deal_purchases.daily_deal_id = daily_deals.id"
      end
      
    end
  end
end
