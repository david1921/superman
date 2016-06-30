class Job < ActiveRecord::Base

  belongs_to :publisher

  named_scope :with_key, lambda { |key| { :conditions => { :key => key }}}
  named_scope :latest_incremental_run, :conditions => "increment_timestamp IS NOT NULL", :order => "increment_timestamp DESC", :limit => 1
  named_scope :processed, :conditions => "finished_at IS NOT NULL"

  def self.increment_timestamp
    Time.now
  end

  def self.last_finished_at(job_key)
    with_key(job_key).sort_by(&:finished_at).last.try(:finished_at)
  end
  
  def self.start!(key)
    create!(:key => key, :started_at => Time.now)
  end
  
  def finish!(attr_values)
    update_attributes({ :finished_at => Time.now }.merge(attr_values))
  end

  def self.run!(key, options = nil)
    raise "Must be called with a block" unless block_given?
    
    if options.nil?
      warn "[DEPRECATED] Single argument Job.run! assumes an incremental run but shouldn't.\n" +
           "Try the two argument Job.run!(key, options) instead. Use the options hash to\n" +
           "specify whether the run should be incremental"

      [].tap do |results|
        transaction do
          job = create!(:key => key, :started_at => Time.now)
          results << yield(last_increment_timestamp(key), (this_increment_timestamp = Time.now))
          job.update_attributes! :increment_timestamp => this_increment_timestamp, :finished_at => Time.now
        end
      end.first
    else
      options.assert_valid_keys(:file_name, :incremental)
      result = nil
      transaction do
        job = create!(:key => key, :started_at => Time.now, :file_name => options[:file_name])
        result = if options[:incremental]
          yield(last_increment_timestamp(key), job.increment_timestamp = Time.now, job)
        else
          yield
        end
        
        verify_active_connections!
        job.finished_at = Time.now
        job.save!
      end
      result
    end    
  end
  
  private
  
  def self.last_increment_timestamp(key)
    with_key(key).latest_incremental_run.first.try(:increment_timestamp)
  end
end
