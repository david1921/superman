module Report::Offer
  def impressions_count(dates)
    impression_counts.sum(:count, :conditions => {:created_at => times_for_dates(dates)})
  end
  
  def clicks_count(dates)
    click_counts.sum(:count, :conditions => { :created_at => times_for_dates_for_click_counts(dates), :mode => "" })
  end
  
  def facebooks_count(dates)
    click_counts.sum(:count, :conditions => {:created_at => times_for_dates(dates), :mode => "facebook"})
  end
  
  def twitters_count(dates)
    click_counts.sum(:count, :conditions => {:created_at => times_for_dates(dates), :mode => "twitter"})
  end
  
  def txts_count(dates)
    txts.count(:conditions => {:created_at => times_for_dates(dates), :status => "sent"})
  end

  def prints_count(dates)
    leads.count(:conditions => {:print_me => true, :created_at => times_for_dates(dates)})
  end
  
  def emails_count(dates)
    leads.count(:conditions => {:email_me => true, :created_at => times_for_dates(dates)})
  end
  
  def voice_messages_count(dates)
    voice_messages.count(:conditions => {:created_at => times_for_dates(dates), :status => "sent"})
  end
  
  def calls_count(dates)
    voice_messages_count(dates)
  end
  
  private
    
  def times_for_dates(dates)
    Time.zone.parse(dates.begin.to_s) .. Time.zone.parse(dates.end.to_s).end_of_day
  end
  
  def times_for_dates_for_click_counts(dates)
    Time.parse("#{dates.begin.to_s}T00:00:00Z") .. Time.zone.parse(dates.end.to_s).end_of_day
  end
  
end
