module Drop
  class Subscriber < Liquid::Drop
    delegate :hashed_id, :name, :email, :other_options, :zip_code, :gender, :valid?, :to => :subscriber

    attr_reader :subscriber

    def initialize(subscriber)
      @subscriber = subscriber
    end

  end
end
