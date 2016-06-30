class FixBadCategoriesOffersContraint < ActiveRecord::Migration

	def self.categories_offers_table_name
		"categories_offers"
	end

	def self.categories_offers_constraint_name
		"categories_offers_ibfk_2"
	end

	def self.offer_id_foreign_key
		"offer_id"
	end

	def self.new_constraint_table_name
		"offers"
	end

	def self.contraint_column_name
		"id"
	end

  def self.up
  	ActiveRecord::Base.connection.execute("ALTER TABLE #{categories_offers_table_name} DROP FOREIGN KEY #{categories_offers_constraint_name}")
  	ActiveRecord::Base.connection.execute("ALTER TABLE #{categories_offers_table_name} ADD CONSTRAINT #{categories_offers_constraint_name} FOREIGN KEY (#{offer_id_foreign_key}) REFERENCES #{new_constraint_table_name}(#{contraint_column_name}) ON DELETE CASCADE")
  end

  def self.down
  	raise NotImplementedError, "can not undo since there is no 'tmp_old_offers' table" 
  end
end
