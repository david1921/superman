require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class Addresses::Codes::UsTest

class Addresses::Codes::UsTest < ActiveSupport::TestCase
  include ::Addresses::Codes::US

  context "STATE_NAMES_BY_CODE" do
    should "have state names for all of the state codes in Addresses::Codes::US::STATE_CODES" do
      STATE_CODES.each do |code|
        assert STATE_NAMES_BY_CODE[code], "#{code} does not have a state name"
      end
    end
  end

end