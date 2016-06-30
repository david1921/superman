module Export
  module SanctionScreening
    module DailyDealPayment

      def self.cleanup
        ::DailyDealPayment.has_name_on_card.missing_sanctions_data.each do |payment|
          payment.populate_billing_first_and_billing_last_from_name_on_card
          payment.save!
        end
      end

    end
  end
end
