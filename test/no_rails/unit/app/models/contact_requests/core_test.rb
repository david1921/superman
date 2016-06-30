require File.dirname(__FILE__) + "/../../models_helper"

class ContactRequests::CoreTest < Test::Unit::TestCase

  def setup
    @obj = Object.new.extend(ContactRequests::Core)
  end

  context "#deliver" do
    should "deliver a support contact request email when valid" do
      publisher = mock('publisher')
      @obj.stubs(:publisher).returns(publisher)
      @obj.stubs(:valid?).returns(true)
      @obj.expects(:call_publishers_mailer).with(:deliver_object, publisher, @obj)
      @obj.deliver
    end

    should "return false when invalid" do
      @obj.stubs(:valid?).returns(false)
      assert !@obj.deliver
    end
  end

  context "#email_subject" do
    should "interpolate the subject format string when present" do
      @obj.stubs(:attribute_names).returns(['attr1', 'attr2'])
      @obj.stubs(:attr1).returns("attribute 1")
      @obj.stubs(:attr2).returns("attribute 2")
      @obj.stubs(:email_subject_format).returns("{{ attr1 }} {{attr2}} {do not replace}")
      assert_equal "attribute 1 attribute 2 {do not replace}", @obj.email_subject
    end

    should "return nil when subject format is not present" do
      @obj.stubs(:email_subject_format).returns(nil)
      assert_nil @obj.email_subject

      @obj.stubs(:email_subject_format).returns("")
      assert_nil @obj.email_subject
    end
  end
end
