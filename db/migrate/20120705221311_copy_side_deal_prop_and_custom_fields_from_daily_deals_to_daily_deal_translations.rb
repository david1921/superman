class CopySideDealPropAndCustomFieldsFromDailyDealsToDailyDealTranslations < ActiveRecord::Migration
  def self.up
    sql =  <<-SQL
        UPDATE daily_deals dd, daily_deal_translations t SET
          t.side_deal_value_proposition = dd.side_deal_value_proposition,
          t.side_deal_value_proposition_subhead = dd.side_deal_value_proposition_subhead,
          t.custom_1 = dd.custom_1,
          t.custom_2= dd.custom_2,
          t.custom_3 = dd.custom_3
        WHERE t.daily_deal_id = dd.id
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.down  
  end
end
