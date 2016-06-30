class CreateConsumerDealRelevancyScores < ActiveRecord::Migration
  def self.up
    create_table :consumer_deal_relevancy_scores do |t|
      t.integer :consumer_id
      t.integer :daily_deal_id
      t.integer :relevancy_score
      t.timestamps
    end
    add_index :consumer_deal_relevancy_scores, :consumer_id
  end

  def self.down
    drop_table :consumer_deal_relevancy_scores
    remove_index :consumer_deal_relevancy_scores, :consumer_id
  end
end
