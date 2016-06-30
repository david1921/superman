class AddSideDealPropositionsAndCustomFieldsToDailyDealTranslations < ActiveRecord::Migration
  def self.up
  	add_column_using_tmp_table :daily_deal_translations, :side_deal_value_proposition, :string
  	add_column_using_tmp_table :daily_deal_translations, :side_deal_value_proposition_subhead, :string
  	add_column_using_tmp_table :daily_deal_translations, :custom_1, :string
  	add_column_using_tmp_table :daily_deal_translations, :custom_2, :string
  	add_column_using_tmp_table :daily_deal_translations, :custom_3, :string
  end

  def self.down
  	remove_column_using_tmp_table :daily_deal_translations, :side_deal_value_proposition
  	remove_column_using_tmp_table :daily_deal_translations, :side_deal_value_proposition_subhead
  	remove_column_using_tmp_table :daily_deal_translations, :custom_1
  	remove_column_using_tmp_table :daily_deal_translations, :custom_2
  	remove_column_using_tmp_table :daily_deal_translations, :custom_3
  end
end
