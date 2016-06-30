module Analog
  module ThirdPartyApi
    module Coolsavings
      class MemberExportRequest < MemberRequest
        def path
          url.export_path
        end
      end
    end
  end
end
