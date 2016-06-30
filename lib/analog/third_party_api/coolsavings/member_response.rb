module Analog
  module ThirdPartyApi
    module Coolsavings
      class MemberResponse

        attr_reader :raw

        def initialize(raw)
          @raw = raw
        end

        def parse!
          raise InvalidResponse.new if is_invalid?
          raise ErrorResponse.new(errors) if is_error?
          attributes
        end

        def attributes
          return @attributes unless @attributes.nil?
          @attributes = {}
          data_lines.each do |line|
            key, val = line.split('=')
            if key.present?
              val ||= ""
              @attributes[key.strip] = val.strip
            end
          end
          @attributes
        end

        def errors
          data_lines
        end

        def status_line
          @status_line ||= lines[0].strip
        end

        def data_lines
          @data_lines ||= (lines[1..-1] || [])
        end

        def lines
          @lines ||= @raw.split("\n")
        end

        def is_okay?
          status_line =~ /^0 OK/
        end

        def is_error?
          status_line =~ /^1 ERR/
        end

        def is_valid?
          is_okay? || is_error?
        end

        def is_invalid?
          !is_valid?
        end

      end
    end
  end
end
