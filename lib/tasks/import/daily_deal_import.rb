require 'net/http'
require 'net/https'
require 'uri'

module Import
  module DailyDealImport
    module FTP
      include Analog::Say
      
      class << self

        def select_files_ready_to_process(publisher, remote_files, file_extension="xml")
          files_to_process, sig_files = remote_files.partition {|f| f.include? file_extension }
          sig_files_no_extension = sig_files.map { |f| File.basename(f, ".sig") }
          files_to_process_with_sig_files = files_to_process.select { |f| sig_files_no_extension.include?(File.basename(f, ".#{file_extension}")) }
          select_unprocessed_files(publisher, files_to_process_with_sig_files)
        end

        def select_unprocessed_files(publisher, files)
          files - publisher.jobs.processed.map(&:file_name)
        end

        def download_files(uploader, publisher_config, remote_files)
          uploader.sftp_open(publisher_config) do |sftp|
            remote_files.each do |file_to_download|
              remote_path = "#{publisher_config[:path]}/#{file_to_download}"
              local_path = "tmp/#{file_to_download}"
              say "Downloading #{remote_path} to #{local_path}..."
              sftp.download(remote_path, local_path)
            end
          end
        end

        def import_files_and_upload_response_files(publisher, local_files, uploader, publisher_config)
          local_files.each do |file|
            say "Importing file #{file}..."
            response_file = ::Import::DailyDeals::DailyDealsImporter.daily_deals_import(publisher, "tmp/#{file}")
            say "Uploading response file #{response_file}..."
            uploader.upload(publisher_config, response_file)
          end
        end

        def import_zip_code_files_and_upload_response_files(publisher, local_files, uploader, publisher_config)
          local_files.each do |file|
            say "Importing file #{file}..."
            importer = ::Import::MarketZipCodes::MarketZipCodesImporter.new(publisher, "tmp/#{file}")
            importer.import
            response_file = importer.response_file_name
            say "Uploading response file #{response_file}..."
            uploader.upload(publisher_config, response_file)
          end
        end

      end
    end

    module HTTP
      include Analog::Say

      class << self

        def download_to_file(full_url, to_here, options = {})
          basic_auth = options[:basic_auth]
          uri = URI.parse(full_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 240
          request = Net::HTTP::Get.new("#{uri.path}?#{uri.query}")
          if uri.scheme == "https"
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          if basic_auth.present?
            request.basic_auth basic_auth[:username], basic_auth[:password]
          end

          response = http.request(request)
          File.open(to_here, "wb") { |f| f.write(response.body) }
          response
        end

        def post_file(full_url, file_to_post, options = {})
          basic_auth = options[:basic_auth]

          say "  POST: #{file_to_post}"
          say "  TO: #{full_url}"

          uri = URI.parse(full_url)
          http = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Post.new(uri.path + '?' + (uri.query || ''))
          if basic_auth.present?
            request.basic_auth basic_auth[:username], basic_auth[:password]
          end

          request.body = File.read(file_to_post)
          if full_url.starts_with?("https")
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          http.request(request)
        end

      end
    end

  end
end