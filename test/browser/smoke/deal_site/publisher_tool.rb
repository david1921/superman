require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require File.dirname(__FILE__) + "/deal_site"

#
# Only useful if you have a database full of purchases.
# Runs through each publisher and makes sure the purchase email is good.
# Normally this is done as part of the regular smoke run
#
module Smoke
  module DealSite
    class PublisherTool
      include ::Smoke::Logger

      def run(kickoff_message)
        messages.banner do
          log kickoff_message
        end
        validator = Smoke::PageValidator.new(messages)
        publishers = Publisher.all
        complete = 0
        total = publishers.size
        publishers.each do |publisher|
          path = "#{publisher.label}"
          messages.banner do
            begin
              log publisher.label
              messages.indent
              run_one_publisher(path, publisher, validator)
            rescue => e
              error(publisher.label, path, e)
            ensure
              messages.outdent
              complete += 1
            end
            log "#{complete}/#{total}"
          end
        end
        messages.banner do
          messages.all.each do |msg|
            puts msg
          end
          puts "Done"
        end
      end

      def run_one_publisher(path, publisher, validator)
        raise "Subclasses implement"
      end

      def messages
        @messages ||= Smoke::Messages.new
      end

    end
  end
end
