class ExpectedEmailBlast < ActiveRecordWithoutTable

  attr_accessor :daily_deal, :blast_at, :scheduled_mailing

  def init(options={})
    self.daily_deal = options[:daily_deal]
    self.blast_at = options[:blast_at]
    self.scheduled_mailing = options[:scheduled_mailing]
  end

  def ==(other)
    daily_deal == other.daily_deal && blast_at == other.blast_at
  end

  def as_json(options={})
    {
        :daily_deal => daily_deal.attributes,
        :blast_at => blast_at.try(:iso8601),
        :publisher => daily_deal.publisher.attributes,
        :scheduled_mailing => scheduled_mailing.try(:attributes)
    }
  end

  class << self
    def search(publisher)
      blast_time = publisher.send_todays_email_blast_at
      scoped_daily_deals = publisher.daily_deals.featured_at(blast_time)

      daily_deals = expecting_email_blast(scoped_daily_deals, blast_time)

      from_daily_deals(daily_deals)
    end

    def from_daily_deals(daily_deals)
      daily_deals.map do |daily_deal|
        blast_at = daily_deal.send_todays_email_blast_at
        new(
            :daily_deal => daily_deal,
            :blast_at => blast_at,
            :scheduled_mailing => ScheduledMailing.find_by_publisher_id_and_mailing_date(daily_deal.publisher_id, blast_at.to_date)
        )
      end
    end


    private

    def expecting_email_blast(daily_deals, blast_time)
      daily_deals.select do |daily_deal|
        daily_deal.expected_email_blast_at?(blast_time)
      end
    end
  end

end