require File.dirname(__FILE__) + "/../test_helper"

class MemberTest < ActiveSupport::TestCase
  def test_create
    member = Member.create!(:email => "foo@example.com")
  end
end
