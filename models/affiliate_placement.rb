class AffiliatePlacement < ActiveRecord::Base
  include HasUuid
  include ActsAsSoftDeletable
  
  belongs_to :affiliate, :polymorphic => true
  belongs_to :placeable, :polymorphic => true
  validates_uniqueness_of :placeable_id, :scope => [:affiliate_id, :affiliate_type]
  
  def as_json(options={})
    ap_json = attributes.slice("placeable_type", "uuid", "placeable_id", "affiliate_id", "affiliate_type", "id")
    publisher_label = affiliate.is_a?(Publisher) ? affiliate.label : ""
    value_proposition = placeable.is_a?(DailyDeal) ? placeable.value_proposition : ""
    {
      "affiliate_placement" => ap_json,
      "publisher_label" => publisher_label,
      "value_proposition" => value_proposition
    }
  end
  
end
