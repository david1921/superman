module Analog
  module ThirdPartyApi
    module Coolsavings
      class MemberImportRequest < MemberRequest
        def path
          url.import_path
        end
      end
    end
  end
end
