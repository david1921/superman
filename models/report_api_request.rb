class ReportApiRequest < ApiRequest
  attr_reader :web_coupon_ids
  attr_reader :txt_coupon_ids
  
  with_options :with => /\A\d{4}-\d{2}-\d{2}\z/ do |report_api_request|
    report_api_request.validates_format_of :dates_begin_before_type_cast
    report_api_request.validates_format_of :dates_end_before_type_cast
  end
  
  def web_coupon_ids=(value)
    @web_coupon_ids = value.to_s.split(",").map(&:to_i)
  end
  
  def txt_coupon_ids=(value)
    @txt_coupon_ids = value.to_s.split(",").map(&:to_i)
  end
  
  def error
    case
    when [:dates_begin, :dates_begin_before_type_cast, :dates_end, :dates_end_before_type_cast].any? { |attr| errors.on(attr) }
      ApiRequest::InvalidDateError.new
    end
  end
  
  def txt_counts
    sql =<<-EOF
      SELECT COUNT(*) FROM txts
        INNER JOIN api_requests ON txts.source_type = 'ApiRequest' AND txts.source_id = api_requests.id
      WHERE txts.status = ? AND txts.created_at BETWEEN ? AND ? AND api_requests.publisher_id = ?
    EOF
    [
      Txt.count_by_sql([sql, "sent" , dates_begin.beginning_of_day, dates_end.end_of_day, publisher.id]),
      Txt.count_by_sql([sql, "error", dates_begin.beginning_of_day, dates_end.end_of_day, publisher.id])
    ]
  end

  def call_counts
    conditions = {
      'api_requests.type' => "CallApiRequest",
      'api_requests.publisher_id' => publisher.id,
      'voice_messages.created_at' => (dates_begin.beginning_of_day .. dates_end.end_of_day)
    }
    success_conditions = conditions.merge('voice_messages.status' => "sent")
    failure_conditions = conditions.merge('voice_messages.status' => "error")
    [
      VoiceMessage.count(:joins => :api_request, :conditions => success_conditions),
      VoiceMessage.count(:joins => :api_request, :conditions => failure_conditions)
    ]
  end

  def email_counts
    conditions = {
      :created_at => (dates_begin.beginning_of_day .. dates_end.end_of_day)
    }
    [
      EmailApiRequest.count(:conditions => conditions),
      0
    ]
  end
  
  def counts
    sql =<<-EOF
      SELECT IFNULL(a.report_group, "") AS report_group,
        SUM(IF(t.status = "sent", 1, 0)) AS txts_count_success,
        SUM(IF(t.status = "error", 1, 0)) AS txts_count_failure,
        SUM(IF(v.status = "sent", 1, 0)) AS calls_count_success,
        SUM(IF(v.status = "error", 1, 0)) AS calls_count_failure,
        SUM(IF(a.type = "EmailApiRequest", 1, 0)) AS emails_count_success,
        0 AS emails_count_failure
      FROM api_requests a
        LEFT JOIN txts t ON t.source_type = 'ApiRequest' AND t.source_id = a.id
        LEFT JOIN voice_messages v ON v.api_request_id = a.id
      WHERE
        a.created_at BETWEEN ? AND ? AND
        a.publisher_id = ?
      GROUP BY a.report_group
    EOF
    ReportApiRequest.find_by_sql([sql, dates_begin.beginning_of_day, dates_end.end_of_day, publisher.id])
  end
  
  def dates
    dates_begin..dates_end
  end
      
  def advertisers_with_offers_and_txt_offers
    advertisers_with_objects = lambda do |ids, collection|
      conditions = ids ? { :id => ids } : {}
      #
      # OrderedHash#merge doesn't take a block, so convert to regular Hash after grouping.
      #
      objects_by_advertiser = Hash[publisher.send(collection).all(:conditions => conditions, :include => :advertiser).group_by(&:advertiser)]
      objects_by_advertiser.merge(objects_by_advertiser) { |_, val, val| { collection => val }}
    end
    advertisers_with_objects.call(@web_coupon_ids, :offers).deep_merge(advertisers_with_objects.call(@txt_coupon_ids, :txt_offers))
  end
end
