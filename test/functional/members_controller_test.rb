require File.dirname(__FILE__) + "/../test_helper"

class MembersControllerTest < ActionController::TestCase
  def test_new
    get(:new)
    assert_response(:success)
    assert_template("new")
    assert(assigns(:member), "@member")
    assert_layout("txt411/application")
  end

  def test_create
    email = "foo@example.com"
    assert_nil(Member.find_by_email(email))

    post(:create, :member => { :email => email })
    assert_response(:redirect)

    member = Member.find_by_email(email)
    assert_not_nil(member)
    assert_redirected_to(member_path(member))
  end

  def test_show
    member = Member.create!(:email => "bar@example.com")
    get(:show, :id => member.to_param)
    assert(assigns(:member), "@member")
    assert_response(:success)
    assert_layout("txt411/application")
  end
end
