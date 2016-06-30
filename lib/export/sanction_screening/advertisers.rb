module Export
  module SanctionScreening
    module Advertisers

      JOB_KEY = "sanction_screening:export_and_uploaded_encrypted_advertiser_file"

      class << self

        def export_to_pipe_delimited_file!(sanction_date)
          date = Time.zone.now.strftime("%Y%m%d%H%M%S")
          filename = Rails.root.join("tmp", "sanction_screening_advertisers_#{date}.txt")
          #
          FasterCSV.open(filename, "w", :col_sep => "|") do |csv|
            #["Merchant Name", "Id", "Address 1", "Address 2", "City", "State", "Postal Code", "Started At", "Launched At", "Terminated At", "Federal Tax Id"]
            csv << [
                "merchant_name", "analog_id", "address_line_1", "address_line_2", "city",
                "state", "zip_code", "start_date", "launch_date", "termination_date", "tax_id"
            ]

            find_stores.each do |store|
              csv << create_row_from_store(store)
            end

          end

          filename
        end

        def find_stores
          Store.all(:include => {:advertiser => { :publisher => :publishing_group }},
                    :conditions => [%Q{publishing_groups.uses_paychex = ? AND
                                      publishers.used_exclusively_for_testing = ? AND
                                      advertisers.used_exclusively_for_testing = ?},
                                      true, false, false])
        end

        def create_row_from_store(store)
          [
              SanctionScreening::NameCleaner.clean(store.advertiser.name),
              store.id,
              store.address_line_1,
              store.address_line_2,
              store.city,
              store.state || store.region,
              store.zip,
              store.started_at.try(:to_formatted_s, :db_date),
              store.launched_at.try(:to_formatted_s, :db_date),
              store.terminated_at.try(:to_formatted_s, :db_date),
              store.federal_tax_id
          ]
        end

        def export_encrypt_and_upload!(passphrase, recipient, sanction_date)
          Job.run!(JOB_KEY, :incremental => false) do
            filename = export_to_pipe_delimited_file!(sanction_date)
            Export::SanctionScreening::Upload.encrypt_upload_and_remove!(filename, passphrase, recipient)
          end
        end
      end
    end
  end
end
