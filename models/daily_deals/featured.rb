module DailyDeals::Featured
  def featured_at?(time)
    featured_date_ranges.any? { |range| range.include?( time ) }
  end

  def became_featured_within_interval_of?(interval, time)
    featured_start = featured_date_ranges.find { |range| range.include?(time) }.try(:begin)
    featured_start && (time >= featured_start) && ((time - featured_start) < interval)
  end

  def current_featured_window
    featured_date_ranges.find { |range| range.include?(Time.now) }
  end
end