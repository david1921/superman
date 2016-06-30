class AddDailyDealVariationTranslationsTable < ActiveRecord::Migration
  def self.up
  	remove_column :daily_deal_variations, :value_proposition
  	DailyDealVariation.create_translation_table!(
  		:value_proposition => :string,
  		:value_proposition_subhead => :string,
  		:voucher_headline => :string,
  		:terms => :text
  	)
  end

  def self.down
  	DailyDealVariation.drop_translation_table!
  	add_column :daily_deal_variations, :value_proposition, :string
  end
end
