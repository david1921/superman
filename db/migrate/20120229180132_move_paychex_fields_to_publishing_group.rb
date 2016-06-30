class MovePaychexFieldsToPublishingGroup < ActiveRecord::Migration
  def self.up
    remove_column_using_tmp_table :publishers, :uses_paychex
    remove_column_using_tmp_table :publishers, :paychex_initial_payment_percentage
    remove_column_using_tmp_table :publishers, :paychex_num_days_after_which_full_payment_released
    add_column_using_tmp_table :publishing_groups, :uses_paychex, :boolean, :default => false, :null => false
    add_column_using_tmp_table :publishing_groups, :paychex_initial_payment_percentage, :decimal, :precision => 5, :scale => 2
    add_column_using_tmp_table :publishing_groups, :paychex_num_days_after_which_full_payment_released, :integer

    bcbsa_publishing_group = PublishingGroup.find_by_label("bcbsa")
    bcbsa_publishing_group.update_attributes(
      :uses_paychex => true,
      :paychex_initial_payment_percentage => 90.0,
      :paychex_num_days_after_which_full_payment_released => 90
    ) if bcbsa_publishing_group.present?

    rr_publishing_group = PublishingGroup.find_by_label("rr")
    rr_publishing_group.update_attributes(
      :uses_paychex => true,
      :paychex_initial_payment_percentage => 80.0,
      :paychex_num_days_after_which_full_payment_released => 44
    ) if rr_publishing_group.present?
  end

  def self.down
    add_column_using_tmp_table :publishers, :uses_paychex, :boolean, :default => false, :null => false
    add_column_using_tmp_table :publishers, :paychex_initial_payment_percentage, :decimal, :default => 80.0, :precision => 5, :scale => 2
    add_column_using_tmp_table :publishers, :paychex_num_days_after_which_full_payment_released, :integer, :default => 44
    remove_column_using_tmp_table :publishing_groups, :uses_paychex
    remove_column_using_tmp_table :publishing_groups, :paychex_initial_payment_percentage
    remove_column_using_tmp_table :publishing_groups, :paychex_num_days_after_which_full_payment_released

    bcbsa_publishing_group = PublishingGroup.find_by_label("bcbsa")
    execute "UPDATE publishers
             SET uses_paychex = 1,
                 paychex_initial_payment_percentage = 90.0,
                 paychex_num_days_after_which_full_payment_released = 90
             WHERE publishing_group_id = #{bcbsa_publishing_group.id}" if bcbsa_publishing_group.present?

    rr_publishing_group = PublishingGroup.find_by_label("rr")
    execute "UPDATE publishers
             SET uses_paychex = 1,
                 paychex_initial_payment_percentage = 80.0,
                 paychex_num_days_after_which_full_payment_released = 44
             WHERE publishing_group_id = #{rr_publishing_group.id}" if rr_publishing_group.present?
  end
end
