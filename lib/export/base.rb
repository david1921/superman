require 'tasks/uploader'

module Export
  
  class Base
    
    DEFAULT_BATCH_SIZE = 50_000

    class << self
      
      def export_to_csv!
        ensure_job_key_set!
        export_filename = get_export_filename
        Job.run!(@job_key, :file_name => export_filename, :incremental => incremental_run?) do |increment_start_at, increment_end_at|
          FasterCSV.open(export_filename, "w") do |csv|
            write_csv_headers(csv)
            write_csv_rows(csv, increment_start_at, increment_end_at)
          end
        end
        export_filename
      end
      
      def upload_csv!
        csv_filename = export_to_csv!
        gzipped_csv_filename = gzip_file(csv_filename)
        upload_file_to_ftp_server(gzipped_csv_filename)
      end
      
      def upload_file_to_ftp_server(filename)
        must_be_overridden!
      end
      
      def column(c)
        @columns ||= []
        @columns << c
      end

      def get_column_label_index(column_name)
        @columns.map { |c| c.keys.first }.index(column_name)
      end

      protected
      
      def job_key(key)
        @job_key = key
      end
      
      def get_export_filename
        must_be_overridden!
      end

      def write_csv_headers(csv)
        csv << csv_headers
      end
      
      def ensure_file_exists!(filename)
        raise ArgumentError, "file '#{filename}' does not exist" unless filename.present? && File.exists?(filename)
      end
      
      def gzip_file(filename)
        ensure_file_exists!(filename)

        system "gzip", filename
        "#{filename}.gz"
      end
      
      def upload_file_to_ftp_server(filename)
        must_be_overridden!
      end

      def write_csv_rows(csv, increment_start_at = nil, increment_end_at = nil)
        get_csv_rows_in_batches(increment_start_at, increment_end_at, default_batch_size) do |batch|
          process_batch(batch, csv)
        end
      end
      
      def process_batch(batch, csv)
        batch.each_hash do |row|
          next if omit_row_from_results?(row)

          csv << csv_values.map do |label_value|
            case label_value
              when Proc
                label_value.call(row)
              when Symbol
                row[label_value.to_s]
            end
          end
        end
      end
      
      def omit_row_from_results?(row)
        false
      end
      
      def default_batch_size
        DEFAULT_BATCH_SIZE
      end
      
      def get_csv_rows_in_batches(increment_start_at, increment_end_at, batch_size = 10_000, &batch_handler)
        must_be_overridden!          
      end

      def sql_quote(value)
        ActiveRecord::Base.connection.quote(value)
      end

      def csv_headers
        @columns.map { |c| c.keys.first }
      end

      def csv_values
        @columns.map { |c| c.values.first }
      end

      def format_datetime_as_iso8601(datetime)
        DateTime.strptime(datetime, '%Y-%m-%d %H:%M:%S').to_s(:iso8601)
      end
      
      def format_datetime_as_yyyy_mm_dd(datetime)
        DateTime.strptime(datetime, '%Y-%m-%d %H:%M:%S').strftime("%Y-%m-%d")
      end

      def ensure_job_key_set!
        raise "job key can't be blank (maybe you need to call \"job_key 'some:job:key'\" in your child class?)" unless defined?(@job_key) && @job_key.present?
      end
      
      def incremental_run?
        ENV["INCREMENTAL"].present?
      end
      
      def must_be_overridden!
        raise NotImplementedError, "method '#{caller[0][/`([^']*)'/, 1]}' must be overridden by child class"
      end
      
      def calling_method
        caller[1] =~ /`([^']*)'/ and $1
      end
      
    end
  
  end
  
end