class NotifyPublisherOfConsumerCreation
  CONSUMER_POST_TEST_URL = "http://dev.api.tinyinfo.us"
  CONSUMER_POST_PROD_URL = "http://dev.api.tinyinfo.us"

  @queue = :notify_third_parties_of_consumer_creation

  def self.perform(consumer_id)
    consumer = Consumer.find(consumer_id)
    publisher = consumer.publisher

    Rails.logger.info "--- Handling NotifyPublisherOfConsumerCreation job for consumer #{consumer.id} for publisher #{publisher.label} ---"

    if publisher.notify_third_parties_of_consumer_creation?
      Rails.logger.info "  - Publisher is configured for notification -- attempting POST"

      begin
        post_url = RAILS_ENV == "production" ? CONSUMER_POST_PROD_URL : CONSUMER_POST_TEST_URL
        path = "/user/create/"
        query_string = "userId:#{consumer.id},token:af1a3e91cc6ccafbeadd81d48ffc2b95"

        url = URI.parse(post_url)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true if post_url == CONSUMER_POST_PROD_URL
        response = http.start {|req| req.post(path, query_string) }

        Rails.logger.info "  - Posted to #{post_url}#{path}#{query_string}"
        Rails.logger.info "  - Response code: #{response.code}"

        handle_failed_response(response) if response.code != "200"
      rescue Exception => ex
        Rails.logger.error "  - Exception during third party notification: #{ex.message}"
        raise ex
      end

    else
      Rails.logger.info "  - Publisher is not configured for notification"
    end

    Rails.logger.info "--- Done with NotifyPublisherOfConsumerCreation job for consumer #{consumer.id} for publisher #{publisher.label} ---"
  end

  def self.handle_failed_response(response)
    message = "  - Consumer POST failed to return 200: #{response.code}"
    Rails.logger.info message
    raise message
  end

end