module DailyDeals
  module PDF

    # allows one to preview a sample daily deal certificate.
    #
    # we generate a temporary (in memory) daily deal purchase and certificate
    # so we can follow the same path as when we use concreate daily deal purchases
    # and certificates.
    def to_preview_pdf
      daily_deal_purchase = daily_deal_purchase_for_preview
      daily_deal_certificate = DailyDealCertificate.new( attributes_for_daily_deal_certificate_for_preview.merge(:daily_deal_purchase => daily_deal_purchase) )

      # the following declaration is to get around the has_one through when
      # the models aren't saved to the db.  We are only attaching this
      # new method to the newly created instance of DailyDealCertificate.
      def daily_deal_certificate.daily_deal
        daily_deal_purchase.daily_deal
      end

      daily_deal_purchase.daily_deal_certificates_pdf( [daily_deal_certificate] )
    end

    private

    def daily_deal_purchase_for_preview
      daily_deal_purchases.build(attributes_for_daily_deal_purchase_for_preview)
    end

    def attributes_for_daily_deal_purchase_for_preview
      { :daily_deal => self }
    end

    def attributes_for_daily_deal_certificate_for_preview
      { :redeemer_name => "Jill Smith", :serial_number => "12345678" }
    end

  end
end
