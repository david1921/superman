module BlueCrossBlueShield
  class PlanImporter
    attr_reader :publishers, :errors, :membership_codes

    def initialize(path, publishing_group, options = {})
      @publishers = {}
      @errors = []
      @publishing_group = publishing_group
      @options = options

      @membership_codes = {:additions => {}, :deletions => {}}

      read_all_lines(path)
    end

    def import
      Publisher.transaction do
        begin
          save_publishers
          destroy_deleted_membership_codes
          save_new_membership_codes
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
          @errors.concat(e.record.errors.full_messages)
          failed = true
        rescue => e
          raise e
          failed = true
        end

        if failed || @errors.present? || @options[:dry_run]
          raise ActiveRecord::Rollback
        end
      end
    end

    private

    def read_all_lines(path)
      line_number = 0
      FasterCSV.foreach(path, :headers => true) do |line|
        line = sanitize_line(line)
        load_line(line, line_number)
        line_number += 1
      end
    end

    def sanitize_line(line)
      line = line.to_hash

      line.each_pair do |key, value|
        value = value.try(:strip)

        if value == "Not Available" || value == "Not Applicable"
          value = nil
        end

        line[key] = value
      end

      line
    end

    def load_line(line, line_number)
      plan_name = normalize_name(line["Plan Name Displayed"] || line["Plan Name"])

      if plan_name.blank?
        @errors << "Plan name not given for line: #{line.inspect}"
      else
        launched = line["Participating Plan?"] == "YES"
        label = extract_label_from_example_url(line["Plan Specific URL"], line_number)

        if @publishers[plan_name].present?
          publisher = @publishers[plan_name]
          check_value_did_not_change(publisher, :launched, launched)
          check_value_did_not_change(publisher, :label, label)
        else
          publisher = @publishing_group.publishers.find_by_name!(plan_name)
          publisher.launched = launched
          publisher.label = label
          @publishers[plan_name] = publisher
        end

        if code = line["Plan Alpha Prefix"].try(:strip)
          update_action = line["Update Action"]

          case update_action.downcase
          when "add", "replace"
            action_set = :additions
          when "delete"
            action_set = :deletions
          else
            @errors << "Unknown update action type: #{update_action} on line #{line_number}"
          end

          @membership_codes[action_set][code] = publisher
        end
      end
    end

    def save_publishers
      @publishers.each_pair do |_, publisher|
        publisher.save!
      end
    end

    def find_membership_code(code)
      @publishing_group.publisher_membership_codes.find_by_code(code)
    end

    def destroy_deleted_membership_codes
      @membership_codes[:deletions].each_pair do |code, publisher|
        membership_code = find_membership_code(code)
        membership_code.destroy if membership_code
      end
    end

    def save_new_membership_codes
      @membership_codes[:additions].each_pair do |code, publisher|
        membership_code = find_membership_code(code)

        if membership_code
          membership_code.update_attributes!(:publisher => publisher)
        else
          membership_code = publisher.publisher_membership_codes.create(:code => code)
        end
      end
    end

    def check_value_did_not_change(publisher, key, value)
      if publisher[key] != value
        @errors << "Value for publisher '#{publisher.name}' not the same across all rows: #{key}"
      end
    end

    def normalize_name(name)
      name.gsub(/\s+/, " ").strip if name.present?
    end

    def extract_label_from_example_url(url, line_number)
      url =~ %r{^www\.Blue365deals\.com/([a-zA-Z\-_]+)/$}
      $1
    end

  end
end
