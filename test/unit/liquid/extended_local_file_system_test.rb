require File.dirname(__FILE__) + "/../../test_helper"

class ExtendedLocalFileSystemTest < ActiveSupport::TestCase

  def setup
    @file_system = Liquid::ExtendedLocalFileSystem.new('dir1/dir2')
  end

  test "template_exists? on a file that exists" do
    File.expects(:exists?).once.with(File.join('dir1/dir2', 'foo/_bar.html.liquid')).returns(true)
    assert @file_system.template_exists?('foo/bar')
  end

  test "template_exists? on a file that doesn't exist" do
    assert !@file_system.template_exists?('foo.bar')
  end

  test "full_path should expand to .html.liquid extension" do
    assert_equal 'dir1/dir2/foo/_bar.html.liquid', @file_system.full_path('foo/bar')
  end

end
