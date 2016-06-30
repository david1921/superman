module Report
  module EntertainmentSetup

    def entertainment_setup
      @entertainment        = Factory(:publishing_group)
      Timecop.freeze(Time.zone.now - 10.minutes) do
        @detroit_publisher    = Factory(:publisher,
                                        :name             =>"Detroit",
                                        :label            =>"detroit",
                                        :publishing_group => @entertainment,
                                        :production_host  =>"deals.entertainment.com",
                                        :city             =>"Detroit",
                                        :state            =>"MI",
                                        :zip              =>"11111",
                                        :address_line_1   =>"not_used")

        @detroit_advertiser   = Factory(:advertiser,
                                      :publisher             => @detroit_publisher,
                                      :merchant_id           => "DET1",
                                      :merchant_contact_name => "Det Contact",
                                      :rep_id                => "Det Rep")
        @detroit_advertiser.stores.clear
        Factory(:store,
              :city          =>"Detroit",
              :address_line_1=>"detroit addr line 1",
              :state         =>"MI",
              :zip           =>"99999",
              :advertiser    => @detroit_advertiser)
        Factory(:store,
              :city          =>"Detroit",
              :address_line_1=>"detroit addr 2 line 1",
              :state         =>"MI",
              :zip           =>"88888",
              :advertiser    => @detroit_advertiser)
        @detroit_advertiser.save!

        @detroit_deal             = Factory(:daily_deal,
                                          :short_description => "detroit deal",
                                          :advertiser        =>@detroit_advertiser,
                                          :start_at          => Time.zone.now.beginning_of_day,
                                          :hide_at           => Time.zone.now.end_of_day)
        @john_detroit             = Factory(:consumer,
                                          :publisher=> @detroit_publisher,
                                          :email    =>"john@hello.com", :first_name => "J"*80)
        @jill_detroit             = Factory(:consumer,
                                          :publisher=> @detroit_publisher,
                                          :email    =>"jill@hello.com")
      end

      Timecop.freeze(Time.zone.now - 8.minutes) do
        @dallas_publisher     = Factory(:publisher,
                                      :name             =>"Dallas",
                                      :label            =>"dallas",          
                                      :publishing_group => @entertainment,
                                      :city             =>"Dallas",
                                      :state            =>"TX",
                                      :zip              =>"11111",
                                      :address_line_1   =>"not_used")

        @dallas_advertiser    = Factory(:advertiser,
                                      :publisher   => @dallas_publisher,
                                      :merchant_id => "DAL1")
        @dallas_advertiser.stores.clear
        Factory(:store,
              :city       =>"Dallas",
              :state      =>"TX",
              :advertiser => @dallas_advertiser)
        @dallas_advertiser.save!

        @dallas_deal              = Factory(:daily_deal,
                                          :short_description => "dallas deal",
                                          :advertiser        =>@dallas_advertiser,
                                          :start_at          => Time.zone.now.beginning_of_day,
                                          :hide_at           => Time.zone.now.end_of_day)

        @don_dallas               = Factory(:subscriber,
                                          :publisher=> @dallas_publisher,
                                          :email    =>"don@hello.com")
        @don_dallas.other_options = {:city => "Dallas"}
        @don_dallas.save!
      end

      Timecop.freeze(Time.zone.now - 5.minutes) do
        @fortworth_publisher  = Factory(:publisher,
                                      :name             =>"FtWorth",
                                      :label            =>"fortworth",
                                      :publishing_group => @entertainment,
                                      :city             =>"Fort Worth",
                                      :state            =>"TX",
                                      :zip              =>"11111",
                                      :address_line_1   =>"not_used")

        @fortworth_advertiser = Factory(:advertiser,
                                      :publisher   => @fortworth_publisher,
                                      :merchant_id => "FOR1")
        @fortworth_advertiser.stores.clear
        Factory(:store,
              :city       =>"Fort Worth",
              :state      =>"TX",
              :advertiser => @fortworth_advertiser)
        @fortworth_advertiser.save!

        @fortworth_deal           = Factory(:daily_deal,
                                          :short_description => "fortworth deal",
                                          :advertiser        =>@fortworth_advertiser,
                                          :start_at          => Time.zone.now.beginning_of_day,
                                          :hide_at           => Time.zone.now.end_of_day)

        @fred_fortworth           = Factory(:subscriber,
                                        :publisher=> @fortworth_publisher,
                                        :email    =>"fred@hello.com")
        @fred_fortworth.other_options = {:city => "Fort Worth"}
        @fred_fortworth.save!
      end

      Timecop.freeze(Time.zone.now) do
        @phoenix_e_publisher  = Factory(:publisher,
                                        :name             =>"Pheonix East",
                                        :publishing_group => @entertainment,
                                        :launched         => false,
                                        :city             =>"Phoenix",
                                        :state            =>"AZ",
                                        :zip              =>"11111",
                                        :address_line_1   =>"not_used")
        
        @phoenix_e_advertiser = Factory(:advertiser,
                                        :publisher   => @phoenix_e_publisher,
                                        :merchant_id => "PHX1")
        @phoenix_e_advertiser.stores.clear
        Factory(:store,
                :city       =>"Phoenix",
                :state      =>"AZ",
                :advertiser => @phoenix_e_advertiser)
        @phoenix_e_advertiser.save!
        
        @phoenix_e_deal           = Factory(:daily_deal,
                                            :short_description => "phoenix_e deal",
                                            :advertiser        => @phoenix_e_advertiser,
                                            :start_at          => Time.zone.now.beginning_of_day,
                                            :hide_at           => Time.zone.now.end_of_day)
      end
    end
  end
end


