require File.dirname(__FILE__) + "/../../test_helper"

# hydra class Consumers::SaveTest
class Consumers::SaveTest < ActiveSupport::TestCase

 context "save_detecting_duplicate_entry_constraint_violation" do

   should "call save and return save's return value if everything goes well" do
     consumer = Factory.build(:consumer)
     consumer.expects(:save).returns(true)
     assert consumer.save_detecting_duplicate_entry_constraint_violation
   end

   should "reraise exception if it does not contain 'duplicate'" do
     consumer = Factory.build(:consumer)
     e = ActiveRecord::StatementInvalid.new
     e.stubs(:message).returns("Not a match")
     consumer.stubs(:save).raises(e)
     assert_raises ActiveRecord::StatementInvalid do
       consumer.save_detecting_duplicate_entry_constraint_violation
     end
   end

   should "swallow a duplicate entry exception and add an error to the consumer" do
     consumer = Factory.build(:consumer)
     e = ActiveRecord::StatementInvalid.new
     e.stubs(:message).returns("Yadda Duplicate OMG!")
     consumer.stubs(:save).raises(e)
     assert !consumer.save_detecting_duplicate_entry_constraint_violation
     assert_equal "Duplicate entry.  Please try again.", consumer.errors.full_messages.join
   end

 end

end
