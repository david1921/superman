module Smoke
  class UnrecoverableError < RuntimeError

    attr_reader :publisher_label, :details

    def initialize(publisher_label, path, message)
      @publisher_label = publisher_label
      @path = path
      @details = "#{publisher_label} : #{path} : #{message}"
      super(@details)
    end

    def to_s
      @details
    end

  end
end