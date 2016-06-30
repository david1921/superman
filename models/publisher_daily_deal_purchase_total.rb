## Model to store history of purchase totals uploaded to publishing group
## Model intentionally disconnected from purchase tabels to support
##     verification of upload correctness
##
## == Columns
## [publisher_label] label publisher used when deal purchase file was created
## [total] total number of purchases included in deal purchase file
## [date] date the deal purchase file was created
##
class PublisherDailyDealPurchaseTotal < ActiveRecord::Base
  ## [date] date to store publisher totals for
  ## [publisher_totals] hash of publisher totals
  ##     [key] publisher_label
  ##     [value] total number of purchases
  ##   *See `#fetch_totals` for code to construct publisher_totals hash
  def self.set_totals(date, publisher_totals)
    transaction do
      delete_existing_unlisted_labels(date, publisher_totals)
      create_or_update_labels(date, publisher_totals)
    end
  end

  ## date: date to fetch publisher totals for
  ##
  ## Return value: hash of publisher totals
  ##     key: pubisher_label
  ##     value: total number of purchases
  def self.fetch_totals(date)
    fetch_for_date(date).inject(Hash.new) do |output, total|
      output[total.publisher_label] = total.total
      output
    end
  end

  private

  CREATION_DEFAULTS = {:total =>0}
  def self.create_or_update_labels(date, publisher_totals)
    publisher_totals.each do |label, total|
      item = find_or_create_by_date_and_publisher_label(date, label, CREATION_DEFAULTS)
      item.total = total
      item.save
    end
  end

  def self.delete_existing_unlisted_labels(date, publisher_totals)
    labels = publisher_totals.keys
    fetch_for_date(date).each do |total|
      total.destroy unless labels.include? total.publisher_label
    end
  end

  def self.fetch_for_date(date)
    find(:all, :conditions => ["date = ?", date])
  end
end
