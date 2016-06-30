require "net/ftp" 
require "net/sftp"

class Uploader

  DEFAULT_SFTP_RETRY_COUNT = 0

  attr_reader :uploaded_files

  class UploaderTimeout < StandardError
  end
  
  def initialize(upload_config)
    @upload_config = upload_config
    @uploaded_files = []
  end
  
  def test_upload_config(config)
    config = @upload_config[config] if config.is_a?(String) 
    if ftp?(config)
      ftp_open(config) do |ftp|
        ftp.chdir(config[:path]) if config.has_key?(:path)
      end
    elsif sftp?(config)
      sftp_open(config) do |sftp|
        # empty -- just verifying log in
      end
    end
  end 
  
  def ftp?(config)
    return true unless config.has_key?(:protocol)
    config[:protocol] == "ftp"
  end  
  
  def sftp?(config)
    config[:protocol] == "sftp"
  end

  def upload(config, local_file_path) 
    raise "config is required!" unless config.present? 
    config = @upload_config[config] if config.is_a?(String)
    validate_config_upload config
    if ENV["RAILS_ENV"] == "production" || ENV["TEST_UPLOAD"] == "true"
      upload_ftp(config, local_file_path) if ftp?(config)
      upload_sftp(config, local_file_path) if sftp?(config)
    else
      puts "If RAILS_ENV=production or TEST_UPLOAD=true, would have put #{local_file_path} on remote ftp server: #{config[:host]}"
    end
  end

  def validate_config_upload(config)
    raise "config is required!" unless config.present?
    config = @upload_config[config] if config.is_a?(String)  
    [:host, :user, :pass].each do |field|
      raise "Invalid upload config.  Missing: #{field.to_s}." unless config.has_key?(field)
    end
  end
  
  def ftp_open(config)
    # Default Ruby 1.8 timeout unreliable with system calls like FTP
    SystemTimer.timeout(15.minutes) do
      config = @upload_config[config] if config.is_a?(String)
      validate_config_upload config
      ftp = Net::FTP.new
      if not config.has_key?(:port)
        ftp.connect config[:host]
      else
        ftp.passive = true
        ftp.connect config[:host], config[:port]
      end
      ftp.login config[:user], config[:pass]
      if block_given?
        begin
          yield ftp
        ensure
          ftp.close
        end
      end
    end
  end 
  
  def sftp_open(config)
    SystemTimer.timeout(15.minutes, UploaderTimeout) do
      config = @upload_config[config] if config.is_a?(String)
      validate_config_upload config
      if block_given?
        Net::SFTP.start(config[:host], config[:user], :password => config[:pass]) do |sftp|
          yield sftp
        end
      end
    end
  end  

  # returns an array of files from the remote upload dir
  def remote_files(config)
    if ftp?(config)
      remote_files_ftp(config)
    else
      remote_files_sftp(config)
    end
  end

  def remote_path(config, local_path)              
    return File.basename(local_path) unless config.has_key?(:path)
    "#{config[:path]}/#{File.basename(local_path)}"
  end

  private
  
  def upload_ftp(config, local_file_path)
    ftp_open(config) do |ftp|
      ftp.passive = true if config[:pasv]
      ftp.chdir(config[:path]) if config.has_key?(:path)
      ftp.putbinaryfile(local_file_path)
      Rails.logger.info "FTP directory listing: #{ftp.list}"
    end
  end                                                   
  
  def upload_sftp(config, local_file_path)
    retries_used = 0
    max_retries = [0, config[:retry_count] || DEFAULT_SFTP_RETRY_COUNT].max
    remote_file_path = remote_path(config, local_file_path)
    begin
      sftp_open(config) do |sftp|
        if sftp.upload!(local_file_path, remote_file_path)
          @uploaded_files << local_file_path
        end
      end
    rescue UploaderTimeout
      unless @uploaded_files.include?(local_file_path)
        if retries_used < max_retries
          retries_used += 1
          retry
        end
        raise UploaderTimeout, "time's up! file not uploaded"
      end
      # Got a timeout execption, but treat it as a success
      # because the file was included in @uploaded_files
    end
  end

  def remote_files_ftp(config)
    ftp_open(config) do |ftp|
      ftp.passive = true if config[:pasv]
      ftp.chdir(config[:path]) if config.has_key?(:path)
      ftp.nlst
    end
  end

  def remote_files_sftp(config)
    files = []
    sftp_open(config) do |sftp|
      remote_dir = config[:path] || "."
      sftp.dir.foreach("/#{remote_dir}") { |e| files << e.name }
    end
    files.reject {|f| f == "." || f == ".." }
  end

end
