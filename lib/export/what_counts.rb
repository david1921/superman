module Export
  module WhatCounts
    class SubscribeFile
      attr_reader :list_id, :output, :realm, :password, :confirmation_email

      def initialize(output, realm, password, list_id, confirmation_email = nil)
        @output = output
        @realm = realm
        @password = password
        @confirmation_email = confirmation_email
        @list_id = list_id
      end

      def export_subscribers(subscribers)
        wrap_records do |xml|
          subscribers.each do |subscriber|
            xml.record do
              xml.email(subscriber[:email])
              xml.first(subscriber[:first_name]) unless subscriber[:first_name].blank?
              xml.last(subscriber[:last_name]) unless subscriber[:last_name].blank?
              xml.zip(subscriber[:zip_code]) unless subscriber[:zip_code].blank?
            end
          end
        end
      end

      def wrap_records
        xml.instruct!
        xml.transaction do
          xml.realm(realm)
          xml.password(password)
          xml.confirmation_email(confirmation_email) unless confirmation_email.blank?
          xml.command do
            xml.type("subscribe")
            xml.list_id(list_id)
            yield xml if block_given?
          end
        end
      end

      private
      def xml
        @xml ||= Builder::XmlMarkup.new(:target => output, :indent => 2)
      end
    end
  end
end
