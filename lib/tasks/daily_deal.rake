namespace :daily_deal do

  ATTRIBUTES_TO_SYNC_WITH_SOURCE = [
      :expires_on, :price, :value, :quantity, :min_quantity, :max_quantity,
      :advertiser_revenue_share_percentage, :location_required, :national_deal,
      :bar_code_encoding_format, :certificates_to_generate_per_unit_quantity,
      :travelsavers_product_code, :value_proposition, :description, :value_proposition_subhead, :highlights,
      :terms, :reviews, :voucher_steps, :email_voucher_redemption_message,
      :twitter_status_text, :facebook_title_text, :short_description, :disclaimer,
      :redemption_page_description, :side_deal_value_proposition, :side_deal_value_proposition_subhead, :custom_1, :custom_2, :custom_3]

  desc "Email the latest batch of subscriber signups to their publishers. Use DAYS to override publisher's default report interval"
  task :synchronize_syndicated_deal =>  :environment  do
    ids = ENV['IDS'].split(',')
    deals = DailyDeal.find(ids)
    syndicated_deals = deals.select{|d| d.syndicated?}
    raise "all deals must be a source deal: #{syndicated_deals.map(&:id).join(',')}" if syndicated_deals.any?
    deals.each do |deal|
      puts "synchronizing deal: #{deal.id}"
      synchronize_attributes(deal)
    end

  end


  def synchronize_attributes(deal)
    deal.syndicated_deals.each do | syndicated_deal |
      puts "  updating syndicated deal: #{syndicated_deal.id}"
      syndicated_deal.instance_variable_set(:@syncing_with_source, true)
      ATTRIBUTES_TO_SYNC_WITH_SOURCE.each do |attr|
        translation_attr = deal.class.translated_attribute_names.include? attr
        if translation_attr
          copy_translation_attribute(deal, syndicated_deal, attr)
        else
          syndicated_deal.send("#{attr}=", scrub_synchronization_attribute(deal,attr))
        end
      end
      syndicated_deal.save!
    end
  end

  # [BR] some of the attributes we copy are translated by the globalize2 gem.  The globalize2 gem uses the locale
  # class variable to determine which language to use.
  def copy_translation_attribute(deal, syndicated_deal, attr)
    original_locale = deal.class.locale
    deal.translated_locales.each do |locale|
      deal.class.locale = locale
      syndicated_deal.send("#{attr}=", scrub_synchronization_attribute(deal,attr))
    end
    deal.class.locale = original_locale
  end

  #[BR] some of the attributes we copy are formatted and we need the original raw data.  This method strips
  # off additional formatting applied by acts_as_textiled
  def scrub_synchronization_attribute(deal,attr)
    if deal.class.respond_to?(:textiled_attributes) && deal.class.textiled_attributes.include?(attr)
      new_value = deal.send("#{attr}_source")
    else
      new_value = deal.send(attr)
    end
  end

end
