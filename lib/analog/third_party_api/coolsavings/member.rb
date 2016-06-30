module Analog
  module ThirdPartyApi
    module Coolsavings
      class Member

        attr_reader :email, :md5password

        def self.create_with_literal_password(email, password)
          Member.new(email, password.md5)
        end

        def initialize(email, md5password)
          @email = email
          @md5password = md5password
        end

        def authentic?
          begin
            get_attributes!
            true
          rescue ErrorResponse => e
            false
          end
        end

        def get_attributes!
          MemberExportRequest.new(MemberUrl.new(email, md5password)).execute
        end

        def set_attributes!(attributes)
          MemberImportRequest.new(MemberUrl.new(email, md5password, attributes)).execute
        end

      end
    end
  end
end
