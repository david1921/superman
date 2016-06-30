module Import
  module DailyDeals

    class ImporterError < Struct.new(:attribute, :message); end

    class ImporterErrors

      include Enumerable

      attr_reader :errors

      def initialize
        @errors = []
      end

      def add(attribute, message)
        @errors << ImporterError.new(attribute, message)
      end

      def valid?
        !errors?
      end

      def errors?
        @errors.present?
      end

      def each
        @errors.each { |e| yield e }
      end

      def size
        @errors.size
      end
    end
  end
end
