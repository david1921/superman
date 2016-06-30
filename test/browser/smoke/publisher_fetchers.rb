require File.dirname(__FILE__) + "/logger"

module Smoke

  class RemotePublisherWithActiveDealsFetcher

    include Smoke::Logger

    def initialize(source)
      @source = source
    end

    def publishers
      log "Fetching publishers"
      Resources::Publisher.get(@source).map { |publisher_attributes| { :id => publisher_attributes["id"], :label => publisher_attributes["label"], :parent_theme => publisher_attributes["parent_theme"] }}
    end

  end

end
