class ImpressionCount < ActiveRecord::Base
  belongs_to :viewable, :polymorphic => true
  belongs_to :publisher
  
  def self.record(viewable, publisher_id, time=nil)
    time = (time || Time.now).beginning_of_day
    connection.execute %Q{
      INSERT INTO impression_counts (viewable_type, viewable_id, publisher_id, created_at, updated_at, count)
      VALUES ('#{viewable.class.name}', #{viewable.id}, #{publisher_id}, '#{time.to_formatted_s(:db)}', NOW(), 1)
      ON DUPLICATE KEY UPDATE updated_at = NOW(), count = count + 1
    }
  end
end
