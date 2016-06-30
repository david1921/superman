class RenameSideDealAndCustomColumnsOnDailyDeals < ActiveRecord::Migration
  def self.up
    with_tmp_table :daily_deals do |tmp_table|
      rename_column tmp_table, :side_deal_value_proposition, :side_deal_value_proposition_TEMP
      rename_column tmp_table, :side_deal_value_proposition_subhead, :side_deal_value_proposition_subhead_TEMP
      rename_column tmp_table, :custom_1, :custom_1_TEMP
      rename_column tmp_table, :custom_2, :custom_2_TEMP
      rename_column tmp_table, :custom_3, :custom_3_TEMP
    end
  end

  def self.down
    with_tmp_table :daily_deals do |tmp_table|
      rename_column tmp_table, :side_deal_value_proposition_TEMP, :side_deal_value_proposition
      rename_column tmp_table, :side_deal_value_proposition_subhead_TEMP, :side_deal_value_proposition_subhead
      rename_column tmp_table, :custom_1_TEMP, :custom_1
      rename_column tmp_table, :custom_2_TEMP, :custom_2
      rename_column tmp_table, :custom_3_TEMP, :custom_3
    end
  end
end
