require File.dirname(__FILE__) + "/../../../../test_helper"

class Export::SanctionScreening::NameCleanerTest < Test::Unit::TestCase

  context "cleanup_name" do

    should "not process some names" do
      assert_equal "foobar", Export::SanctionScreening::NameCleaner.clean("foobar")
    end

    should "replace funny smart apostrophes with ascii apostrophes" do
      assert_equal "San Antonio Children's Museum", Export::SanctionScreening::NameCleaner.clean("San Antonio Children’s Museum")
    end

    should "handle nil string" do
      assert_equal nil, Export::SanctionScreening::NameCleaner.clean(nil)
    end

    should "handle empty string" do
      assert_equal "", Export::SanctionScreening::NameCleaner.clean("")
    end

    should "not convert regular apostrophe" do
      assert_equal "San Antonio Children's Museum", Export::SanctionScreening::NameCleaner.clean("San Antonio Children's Museum")
    end

  end

end
