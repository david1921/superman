require File.dirname(__FILE__) + "/../../models_helper"

class Stores::CoreTest < Test::Unit::TestCase
  def setup
    @store = Object.new.extend(Stores::Core)
  end

  context "#started_at" do
    should "return created_at" do
      created_at = Time.parse("2012-04-25 12:34:56")
      @store.stubs(:created_at).returns(created_at)
      assert_equal created_at, @store.started_at
    end
  end
end