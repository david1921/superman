module Publishers
  module Silverpop

    def create_silverpop_contact_list_as_needed!(silverpop)
      return if silverpop_list_identifier.present?
      return if publishing_group.silverpop_database_identifier.nil?
      contact_list_name = "#{Rails.env.to_s}-#{publishing_group.silverpop_database_identifier}-#{label}"
      self.silverpop_list_identifier = silverpop.contact_list_id_if_exists(contact_list_name)
      unless self.silverpop_list_identifier.present?
        self.silverpop_list_identifier = silverpop.create_contact_list(publishing_group.silverpop_database_identifier, contact_list_name)
      end
      save!
    end

  end
end
