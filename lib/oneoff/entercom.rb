module Oneoff
  
  module Entercom
    
    def self.copy_hof_consumers_to_ocala!
      entercom_gainsville = Publisher.find_by_label!("entercom-gainesville")
      entercom_ocala = Publisher.find_by_label!("entercom-ocala")
      
      entercom_gainsville.consumers.each do |c|
        next if entercom_ocala.consumers.exists?(:email => c.email)

        new_consumer = Consumer.create! :email => c.email,  :name => c.name,
                                        :crypted_password => c.crypted_password,
                                        :publisher_id => entercom_ocala.id,
                                        :agree_to_terms => true, :activated_at => Time.now,
                                        :credit_available => 0
        new_consumer.salt = c.salt
        new_consumer.remote_record_id = c.remote_record_id
        new_consumer.save!
      end
    end
    
  end
  
end