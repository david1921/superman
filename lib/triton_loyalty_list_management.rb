module TritonLoyaltyListManagement
  def update_triton_loyalty_list!
    Job.run! "#{self.class.name.underscore}:#{label}:update_triton_loyalty_list", :incremental => true do |last_increment_timestamp, this_increment_timestamp|
      Consumer.update_from_subscribers!(self, subscribers_increment(last_increment_timestamp, this_increment_timestamp))
    end
    send_updated_consumers_to_triton_loyalty!
  end
  
  private
  
  def subscribers_increment(last_timestamp, this_timestamp)
    wheres, params = [], []
    if this_timestamp
      wheres << "created_at < ?"
      params << this_timestamp
    end
    if last_timestamp
      wheres << "created_at >= ?"
      params << last_timestamp
    end
    subscribers.all(:conditions => [wheres.join(" AND "), *params])
  end
  
  def send_updated_consumers_to_triton_loyalty!
    { :number => 0, :errors => [] }.tap do |return_value|
      consumers.all(:conditions => "remote_record_updated_at IS NULL").each do |consumer|
        begin
          #
          # Following line handles this sequence of events:
          #
          #   + Consumer subscribes or signs up on the daily-deal website
          #   + We upload the Consumer record to Triton
          #   + Consumer begins receiving email from Triton/Silverpop
          #   + Consumer opts out from the Triton DB, using the unsubscribe link in an email
          #   + Consumer resubscribes on the daily-deal website
          #
          resubscribe consumer if consumer.remote_record_id
          
          upload consumer
          return_value[:number] += 1
        rescue Exception => e
          return_value[:errors] << "#{consumer.email}: #{e}"
        end
      end
    end
  end

  def upload consumer
    consumer.remote_record_id = triton_loyalty.update_member(triton_loyalty_options[:site_code], consumer)
    consumer.remote_record_updated_at = Time.zone.now
    consumer.save false
  end
  
  def resubscribe consumer
    subscriptions = { triton_loyalty_options[:subscription_id] => true }
    triton_loyalty.update_member_subscriptions(triton_loyalty_options[:site_code], consumer.remote_record_id, subscriptions)
  end

  def triton_loyalty_options
    @options ||= {}.tap do |options|
      config = YAML.load_file(Rails.root.join("config", "triton_loyalty.yml"))
      options.merge!(config[publishing_group.try(:label)] || {})
      options.merge!(config[label] || {})
      options.symbolize_keys!
    end
  end
  
  def triton_loyalty
    @triton_loyalty ||= TritonLoyalty.new(triton_loyalty_options)
  end
end
