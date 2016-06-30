module Analog
  module ThirdPartyApi
    module Coolsavings
      module Config
        extend self

        def partner_id=(partner_id)
          @partner_id = partner_id
        end

        def partner_id
          @partner_id
        end

        def api_key=(api_key)
          @api_key = api_key
        end

        def api_key
          @api_key
        end

      end
    end
  end
end
