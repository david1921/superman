class SilverpopListMove < ActiveRecord::Base
  include SilverpopListMoves::MoveConsumerToDifferentSilverpopList
  belongs_to :consumer
  belongs_to :old_publisher, :class_name => "Publisher"
  belongs_to :new_publisher, :class_name => "Publisher"
  validates_presence_of :consumer, :old_publisher, :new_publisher, :old_list_identifier, :new_list_identifier
end
