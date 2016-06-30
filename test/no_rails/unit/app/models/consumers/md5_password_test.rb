require File.dirname(__FILE__) + "/../../models_helper"
require 'lib/extensions/string_extensions'

class Consumers::Md5PasswordTest < Test::Unit::TestCase

  context "md5password" do

    should "return the md5 version of a password if the string does not respond to :md5?" do
      assert_equal "mysecret".md5, Consumers::Md5Password.md5_password("mysecret")
    end

    should "return not re-md5 the password if the string does respond to :md5? with true" do
      md5_pass = "mysecret".md5
      md5_pass.instance_eval do
        def md5?
          true
        end
      end
      assert_equal md5_pass, Consumers::Md5Password.md5_password(md5_pass)
    end

    should "return re-md5 the password if the string responds to :md5? with false" do
      md5_pass = "mysecret".md5
      md5_pass.instance_eval do
        def md5?
          false
        end
      end
      assert_equal md5_pass.md5, Consumers::Md5Password.md5_password(md5_pass)
    end

  end

end