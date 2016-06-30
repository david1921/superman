class ConsumerDealRelevancyScore < ActiveRecord::Base
  belongs_to :consumer
  belongs_to :daily_deal

  #
  # === Validations
  #
  validates_presence_of :consumer, :daily_deal, :relevancy_score
  validates_each :relevancy_score, :allow_nil => true do |record, attr, value|
    if value < 0 || value > 100
      record.errors.add attr, '%{attribute} must be between 0 and 100'
    end
  end

end
