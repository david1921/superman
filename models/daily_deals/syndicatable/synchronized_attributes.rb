module DailyDeals::Syndicatable::SynchronizedAttributes

  ATTRIBUTES_TO_SYNC_WITH_SOURCE = [
    :expires_on, :price, :value, :quantity, :min_quantity, :max_quantity,
    :advertiser_revenue_share_percentage, :location_required, :national_deal,
    :bar_code_encoding_format, :certificates_to_generate_per_unit_quantity,
    :travelsavers_product_code]
    # :value_proposition, :description, :value_proposition_subhead, :highlights,
    # :terms, :reviews, :voucher_steps, :email_voucher_redemption_message,
    # :twitter_status_text, :facebook_title_text, :short_description, :disclaimer,
    # :redemption_page_description, :side_deal_value_proposition, :side_deal_value_proposition_subhead, :custom_1, :custom_2, :custom_3

  def update_syndicated_deal_attributes
    syndicated_deals.each do | syndicated_deal |
      syndicated_deal.instance_variable_set(:@syncing_with_source, true)
      ATTRIBUTES_TO_SYNC_WITH_SOURCE.each do |attr|
        syndicated_deal.send("#{attr}=", scrub_synchronization_attribute(attr)) if syndicated_deal.send(attr) != self.send(attr)
      end
    end
  end

  def scrub_synchronization_attribute(attr)
    if self.class.respond_to?(:textiled_attributes) && self.class.textiled_attributes.include?(attr)
      new_value = self.send("#{attr}_plain")
    else
      new_value = self.send(attr)
    end
  end

  def protect_synced_syndicated_deal_attributes
    if !@syncing_with_source && !new_record? && source.present?
      ATTRIBUTES_TO_SYNC_WITH_SOURCE.each do |attr|
        if changes[attr.to_s]
          errors.add(attr, '%{attribute} must be changed in the source deal')
        end
      end
    end
  end
end