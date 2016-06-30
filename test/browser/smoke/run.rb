require 'yaml'
require File.dirname(__FILE__) + "/logger"
require File.dirname(__FILE__) + "/smoke"

module Smoke
  class Run
    include Smoke::Logger

    attr_accessor :publishers
    attr_reader :messages

    def initialize(identifier)
      @identifier = identifier
    end

    def already_succeeded?(label)
      successes.include?(label)
    end

    def already_failed?(label)
      failures.include?(label)
    end

    def already_run?(label)
      already_succeeded?(label) || already_failed?(label)
    end

    def success(label)
      failures.delete(label)
      unless successes.include?(label)
        successes << label
      end
    end

    def failure(label)
      successes.delete(label)
      unless failures.include?(label)
        failures << label
      end
    end

    def delete(labels)
      labels.each do |label|
        successes.delete(label)
        failures.delete(label)
        messages.clear_publisher(label)
      end
      log "Removed #{labels.join(", ")} from successes, failures, and messages"
    end

    def start(force_fresh = false)
      if force_fresh
        destroy
      end
      messages.banner do
        if run_exists?
          log "Found an existing run."
          log "Remove this file #{filename} to start fresh."
          backup_run
          File.open(filename) do |f|
            successes_serialized = f.read
            loaded = YAML::load(successes_serialized)
            if loaded
              @successes = loaded[:successes]
              @failures = loaded[:failures]
              @publishers = loaded[:publishers]
              @messages = loaded[:messages]
              log "#{successes.size} succeeded so far"
              log "#{failures.size} failed so far"
            else
              raise "Run file exists (#{filename} but is empty!"
            end
          end
        else
          log "FRESH RUN"
        end
      end
    end

    def backup_run
      log "Backing up run to #{backup_filename}"
      FileUtils.cp(filename, backup_filename)
    end

    def backup_filename
      "#{filename}-#{Time.now.to_i}.bak"
    end

    def fresh?
      !run_exists?
    end

    def run_exists?
      File.exists?(filename)
    end

    def finished
      save_file
      messages.banner do
        log "Finished.  #{successes.size} successes so far."
        log "Finished.  #{failures.size} failed so far."
        log "To ignore these for next run, remove the file #{filename}"
      end
    end

    def save_file
      File.open(filename, "w") do |f|
        f.write YAML::dump({:publishers => publishers,
                            :successes => successes,
                            :failures => failures,
                            :messages => messages})
      end
    end

    def filename
      File.expand_path("tmp/smoke_run_#{@identifier}.yml", Rails.root)
    end

    def successes
      @successes ||= []
    end

    def failures
      @failures ||= []
    end

    def messages
      @messages ||= Smoke::Messages.new
    end

    def destroy
      File.delete(filename)
    end

    def clear_failures!
      @failures = []
      @messages.clear_errors
    end

    def log_status
      log "#{publishers.size} total publishers."
      remaining = publishers.map {|p| p[:label] } - successes
      log_collection("SUCCESS", successes)
      log_collection("FAILURE", failures)
      log_collection("REMAINING", remaining)
      log_collection("MESSAGES", messages.all)
    end

    def to_go
      publishers.size - (successes.uniq.size + failures.uniq.size)
    end

  end
end