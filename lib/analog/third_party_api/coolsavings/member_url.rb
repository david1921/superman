require 'cgi'

module Analog
  module ThirdPartyApi
    module Coolsavings
      class MemberUrl

        attr_reader :email, :md5password, :attributes

        def initialize(email, md5password, attributes = {})
          raise ArgumentError.new("Missing email") if email.blank?
          raise ArgumentError.new("Missing md5password") if md5password.blank?
          @email = email
          @md5password = md5password
          @attributes = attributes
        end

        def host
          "www.coolsavings.com"
        end

        def port
         https? ? 443 : 80
        end

        def https?
          true
        end

        def export_path
          "/member_export?#{authentication_query_string}"
        end

        def import_path
          "/member_import?#{authentication_query_string}#{query_string_from_attributes}"
        end

        def query_string_from_attributes
          result = ""
          attributes.each_pair do |key, val|
            unless val.blank?
              # email is already in the authentication_query_string
              if key != "EMAIL"
                result << "&#{key}=#{val}"
              end
            end
          end
          result
        end

        def authentication_query_string
          "PARTNER=#{partner_id.to_s}&KEY=#{api_key}&EMAIL=#{email}&PASSWORD=#{md5password}"
        end

        def partner_id
          AppConfig.coolsavings[:partner_id]
        end

        def api_key
          AppConfig.coolsavings[:api_key]
        end

      end
    end
  end
end
