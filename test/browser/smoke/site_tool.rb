require File.expand_path(File.dirname(__FILE__) + "/../../../config/environment")
require File.dirname(__FILE__) + "/../resources/publisher"
require File.dirname(__FILE__) + "/../resources/publishing_group"
require File.dirname(__FILE__) + "/../resources/publishing_groups/market"

require File.dirname(__FILE__) + "/smoke"

module Smoke
  class SiteTool
    include Smoke::Logger
    include Smoke::Capybara
    include Smoke::ResourceHost
    include ::Capybara::DSL

    def initialize(active_resource_source, options)
      @active_resource_source = active_resource_source
      @options = options
      setup_capybara(@options)
      setup_active_resource_host
    end

    def run
      setup_run
      if @options.status?
        exit 0
      end

      begin
        complete = 0
        publishers = filter(@run.publishers, requested_publisher_labels, requested_parent_themes)
        publishers = publishers.reject { |p| @run.already_run?(p[:label]) }
        pre_create_consumers_if_requested(publishers)
        publishers.each do |p|
          publisher_id = p[:id]
          publisher_label = p[:label]
          run_publisher(@run, publisher_id, publisher_label)
          complete += 1
          log "#{complete}/#{publishers.size}"
        end
      ensure
        if messages.all.size > 0
          messages.banner do
            log "ERRORS & WARNINGS".light_red
            log "-----------------".light_red
            messages.all.each do |m|
              puts m
            end
          end
        end
        @run.finished
      end
    end

    def email
      @email ||= if @options.pre_create_consumers?
        @options[:email] || "#{UUIDTools::UUID.random_create.to_s}@yahoo.com"
      else
        @options[:email]
      end
    end

    def password
      @password ||= if @options.pre_create_consumers?
        @options[:password] || "password"
      else
        @options[:password]
      end
    end


    def pre_create_consumers_if_requested(publisher_attrs)
      if @options.pre_create_consumers?
        publishers = publisher_attrs.map { |attrs| Publisher.find(attrs[:id]) }
        Smoke::FakeConsumerCreator.new(email, password).create_one_consumer_for_each_publisher(publishers)
      end
    end

    def setup_run
      @run = Run.new("smoke_test")
      @run.start(@options.fresh_run?)
      @run.publishers = publishers
      if force? || !requested_publisher_labels.nil?
        @run.delete(requested_publisher_labels)
      end
      if @options.clear_failures?
        @run.clear_failures!
      end
      if @options.status?
        @run.log_status
        @run.finished
      end
    end

    def run_publisher(run, publisher_id, publisher_label)
      messages.banner do
        log publisher_label.blue
      end
      messages.indent do
        start = Time.now
        error_count_before_check = checker.error_count
        begin
          checker.check_site(publisher_id, publisher_label)
          error_count_after_check = checker.error_count
          log_timings_etc(publisher_label, run, start)
          run.save_file
          if error_count_before_check == error_count_after_check
            log "#{publisher_label} succeeded".upcase.green
            run.success(publisher_label)
          else
            log "#{publisher_label} failed with #{checker.error_count} errors.".upcase.red
            run.failure(publisher_label)
          end
        rescue Errno::ECONNREFUSED => e_conn
          raise e_conn
        rescue => e
          if @options.save_and_open_page?
            save_and_open_page
          end
          error(publisher_label, current_path, e)
          run.failure(publisher_label)
          log e
          log "Skipping the rest of #{publisher_label}"
          log e.backtrace
        end
      end
    end

    def log_timings_etc(publisher_label, run, start)
      that_took = Time.now - start
      log "#{publisher_label} took #{that_took} seconds"
    end

    def requested_publisher_labels
      @options[:publishers]
    end

    def requested_parent_themes
      @options[:parent_themes]
    end

    def force?
      @options.force?
    end

    def publishers
      if @options[:publishing_group]
        log("only fetching publishers for #{@options[:publishing_group]}".upcase.red)
        @publishers = PublishingGroup.find_by_label(@options[:publishing_group]).live_publishers.map { |p| { :id => p.id, :label => p.label }}
      elsif @options[:active_resource_host]
        log("only fetching publishers with active or future deals".upcase.red)
        @publishers = RemotePublisherWithActiveDealsFetcher.new(@active_resource_source).publishers
      else
        @publishers = Publisher.all.map {|p| {:id => p.id, :label => p.label }}
      end
    end

    def filter(publishers, publisher_labels, parent_themes)
      reject(select(publishers, publisher_labels, parent_themes))
    end

    def select(publishers, publisher_labels, parent_themes)
      return publishers unless publisher_labels || parent_themes
      publisher_labels ||= []
      parent_themes ||= []
      publishers.select { |p| publisher_labels.include?(p[:label]) || parent_themes.include?(p[:parent_theme] || "") }
    end

    def reject(publishers)
      publishers.reject { |p| reject?(p[:label]) }
    end

    def reject?(publisher_label)
      publisher_label.nil?
    end

    def checker
      raise "Implement"
    end

    def messages
      @run.messages
    end

  end
end

