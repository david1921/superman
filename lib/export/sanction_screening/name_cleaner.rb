module Export
  module SanctionScreening
    module NameCleaner

      def self.clean(str)
        return if str.nil?
        str.gsub(/’/, "'")
      end

    end
  end
end
