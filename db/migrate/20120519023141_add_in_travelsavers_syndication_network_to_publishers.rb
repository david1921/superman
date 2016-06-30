class AddInTravelsaversSyndicationNetworkToPublishers < ActiveRecord::Migration
  def self.up
    add_column_using_tmp_table :publishers, :in_travelsavers_syndication_network, :boolean
  end

  def self.down
    remove_column_using_tmp_table :publishers, :in_travelsavers_syndication_network
  end
end
