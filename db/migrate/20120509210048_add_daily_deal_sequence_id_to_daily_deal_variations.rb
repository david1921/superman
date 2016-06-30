class AddDailyDealSequenceIdToDailyDealVariations < ActiveRecord::Migration
  def self.up
  	change_table :daily_deal_variations do |t|
  		t.integer :daily_deal_sequence_id, :null => false
  	end

  	DailyDealVariation.reset_column_information
  	DailyDealVariation.all.collect(&:daily_deal).uniq.each do |daily_deal|
      DailyDealVariation.find(:all, :conditions => ["daily_deal_id = ?", daily_deal.id]).sort{|a,b| a.id <=> b.id}.each_with_index do |variation, index|
  			variation.update_attribute(:daily_deal_sequence_id, index+1)
  		end	
  	end

  	add_index :daily_deal_variations, [:daily_deal_id, :daily_deal_sequence_id], :unique => true, :name => "daily_deal_id_sequence_id"
  end

  def self.down
  	change_table :daily_deal_variations do |t|
  		t.remove :daily_deal_sequence_id
  	end
  	remove_index :daily_deal_variations, :name => "daily_deal_id_sequence_id"
  end
end
