class ScheduledMailing < ActiveRecord::Base
  belongs_to :publisher
  validates_presence_of :publisher, :mailing_date, :mailing_name

  named_scope :mailing_date_between, lambda { |dates|
    { :conditions => ["mailing_date BETWEEN :begin AND :end", { :begin => dates.begin, :end => dates.end }] }
  }

  named_scope :before, lambda{|date| {:conditions => ["mailing_date < :date", {:date => date}]} }
  named_scope :successful, :conditions => "remote_mailing_id IS NOT NULL"

end
