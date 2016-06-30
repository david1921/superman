require 'uuidtools'
require File.dirname(__FILE__) + "/smoke"
require File.dirname(__FILE__) + "/logger"

module Smoke
  class FakeConsumerCreator
    include ::Smoke::Logger

    attr_reader :email, :password

    def initialize(email = nil, password = nil)
      @email = email || "#{UUIDTools::UUID.random_create.to_s}@yahoo.com"
      @password = password || 'password'
    end

    def create_one_consumer_for_each_publisher(publishers)
      single_signon_publishers = publishers.select { |p| p.unique_email_across_publishing_group? }
      non_single_signon_publishers = publishers - single_signon_publishers
      one_publisher_for_each_single_signon_publishing_group = one_publisher_for_each_publishing_group(single_signon_publishers)
      create_consumers(one_publisher_for_each_single_signon_publishing_group)
      create_consumers(non_single_signon_publishers)
    end

    def one_publisher_for_each_publishing_group(publishers)
      publishers_by_publishing_groups = publishers.group_by(&:publishing_group)
      [].tap do |result|
        publishers_by_publishing_groups.each do |pg, publishers|
          if publishers.first
            result << publishers.first
          end
        end
      end
    end

    def create_consumers(publishers)
      publishers.each do |publisher|
        consumer = Smoke::FakeConsumer.new(email, password).create_in_db!(publisher)
        log "Created #{consumer.email} for #{publisher.label} with password '#{consumer.password}'"
      end
    end

  end
end