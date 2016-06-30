require File.dirname(__FILE__) + "/../test_helper"

class VisitorTest < ActiveSupport::TestCase
  def test_create
    Visitor.create!
  end
end
