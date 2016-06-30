class AddAttachmentUpdatedAtFields < ActiveRecord::Migration
  def self.up
    # add_column_using_tmp_table fails to remove its offs temp table without this:
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0;")

    add_column_using_tmp_table :daily_deals, :photo_updated_at, :datetime
    add_column_using_tmp_table :daily_deals, :secondary_photo_updated_at, :datetime

    add_column_using_tmp_table :offers, :photo_updated_at, :datetime
    add_column_using_tmp_table :offers, :offer_image_updated_at, :datetime

    add_column_using_tmp_table :sweepstakes, :photo_updated_at, :datetime
    add_column_using_tmp_table :sweepstakes, :logo_updated_at, :datetime
    add_column_using_tmp_table :sweepstakes, :logo_alternate_updated_at, :datetime

    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1;")
  end

  def self.down
    # remove_column_using_tmp_table fails to remove its offs temp table without this:
    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0;")

    remove_column_using_tmp_table :sweepstakes, :logo_alternate_updated_at
    remove_column_using_tmp_table :sweepstakes, :logo_updated_at
    remove_column_using_tmp_table :sweepstakes, :photo_updated_at

    remove_column_using_tmp_table :offers, :offer_image_updated_at
    remove_column_using_tmp_table :offers, :photo_updated_at

    remove_column_using_tmp_table :daily_deals, :secondary_photo_updated_at
    remove_column_using_tmp_table :daily_deals, :photo_updated_at

    ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=1;")
  end
end
