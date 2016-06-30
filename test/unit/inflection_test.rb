require File.dirname(__FILE__) + "/../test_helper"

class InflectionTest < ActiveSupport::TestCase
  context "Saves" do
    should "not singularize to safe, but remain saves" do 
      assert "Jesus Saves!".singularize, "Jesus Saves!"
    end
  end
end