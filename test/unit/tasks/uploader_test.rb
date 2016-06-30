require File.dirname(__FILE__) + "/../../test_helper"
require File.expand_path("lib/tasks/uploader", RAILS_ROOT)
require File.expand_path("lib/tasks/upload_config", RAILS_ROOT)

class UploaderTest < ActiveSupport::TestCase

  def setup
    @config =  UploadConfig.new({})
    @config[:acme] = {:protocol  => "ftp"}
    @config[:no_protocol_specified] = {}
    @config[:nyny] = {:protocol => "sftp", :path => "Incoming"}
    @uploader = Uploader.new(@config)
  end
  
  test "ftp?" do
    assert @uploader.ftp?(@config[:acme])
    assert !@uploader.ftp?(@config[:nyny])
  end

  test "sftp?" do
    assert @uploader.sftp?(@config[:nyny])
    assert !@uploader.sftp?(@config[:acme])
  end
  
  test "ftp is default protocol" do
    assert @uploader.ftp?(@config[:no_protocol_specified])
  end                  
  
  test "remote path" do 
    assert_equal "Incoming/monkies.txt", @uploader.remote_path(@config[:nyny], "/tmp/monkies.txt")
    assert_equal "Incoming/monkies.txt", @uploader.remote_path(@config[:nyny], "tmp/monkies.txt")
    assert_equal "monkies.txt", @uploader.remote_path(@config[:acme], "tmp/monkies.txt")
  end

  test "upload_sftp should add file to uploaded_files if successful" do
    obj = mock()
    obj.expects(:upload!).returns(true)
    Net::SFTP.stubs(:start).yields(obj)
    Uploader.any_instance.stubs(:validate_config_upload).returns(true)
    @uploader.send(:upload_sftp, @config[:nyny], 'test.txt')
    assert @uploader.uploaded_files.include?('test.txt')
  end

  test "upload_sftp should exit cleanly when timeout happens but file is in uploaded_files" do
    Uploader.any_instance.stubs(:sftp_open).raises(Uploader::UploaderTimeout)
    @uploader.instance_eval { @uploaded_files << 'test.txt' }
    assert_nothing_raised do
      @uploader.send(:upload_sftp, @config[:nyny], 'test.txt')
    end
  end
  
  test "upload_sftp should raise exception when file is not uploaded" do
    Uploader.any_instance.stubs(:sftp_open).raises(Uploader::UploaderTimeout)
    assert_raise Uploader::UploaderTimeout do
      @uploader.send(:upload_sftp, @config[:nyny], 'test.txt')
    end
  end

  test "upload_sftp should be able to retry on error" do
    config_with_retry = @config[:nyny].merge({:retry_count => 2})
    failing_sftp = mock()
    failing_sftp.expects(:upload!).raises(Uploader::UploaderTimeout).twice
    passing_sftp = mock()
    passing_sftp.expects(:upload!).returns(true)
    Net::SFTP.stubs(:start).yields(failing_sftp).then.yields(failing_sftp).then.yields(passing_sftp)
    Uploader.any_instance.stubs(:validate_config_upload).returns(true)

    @uploader.send(:upload_sftp, config_with_retry, 'test.txt')

    assert @uploader.uploaded_files.include?('test.txt')
  end

end
