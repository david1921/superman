class Visitor < ActiveRecord::Base
  def self.new_label
    rand(1_000_000_000_000).to_s
  end
end
