module Export
  module SanctionScreening
    module Publishers
      JOB_KEY = "sanction_screening:export_and_uploaded_encrypted_publisher_file"

      class << self

        def export_to_pipe_delimited_file!
          date = Time.zone.now.strftime("%Y%m%d%H%M%S")
          filename = Rails.root.join("tmp", "sanction_screening_publishers_#{date}.txt")

          FasterCSV.open(filename, "w", :col_sep => "|") do |csv|
            csv << [
              "analog_id", "name", "address_line_1", "address_line_2", "city",
              "state", "zip_code", "start_date", "launch_date",
              "termination_date", "tax_id"
            ]

            find_publishers.each do |publisher|
              csv << create_row_from_publisher(publisher)
            end

          end

          filename
        end

        def find_publishers
          ::Publisher.all(:conditions => { :used_exclusively_for_testing => false }, :order => "id ASC")
        end

        def create_row_from_publisher(publisher)
          [
              publisher.id,
              SanctionScreening::NameCleaner.clean(publisher.name),
              publisher.address_line_1,
              publisher.address_line_2,
              publisher.city,
              publisher.state || publisher.region,
              publisher.zip,
              publisher.started_at.try(:to_formatted_s, :db_date),
              publisher.launched_at.try(:to_formatted_s, :db_date),
              publisher.terminated_at.try(:to_formatted_s, :db_date),
              publisher.federal_tax_id
          ]
        end

        def export_encrypt_and_upload!(passphrase, recipient)
          Job.run!(JOB_KEY, :incremental => false) do
            filename = export_to_pipe_delimited_file!
            Export::SanctionScreening::Upload.encrypt_upload_and_remove!(filename, passphrase, recipient)
          end
        end

      end
    end
  end
end
