# Only want to override some of the production implemenation, not all of it
module Curl
  class MockMulti < Curl::Multi
    def perform
      # Just prevent real HTTP work (and error result)
    end
  end
end