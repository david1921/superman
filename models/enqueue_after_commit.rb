module EnqueueAfterCommit

  def self.included(base)
    base.class_eval do
      attr_accessor :resque_jobs_to_enqueue_in_after_commit
      after_commit :enqueue_resque_jobs
    end
    base.send :include, InstanceMethods
  end

  module InstanceMethods

    def enqueue_resque_job_after_commit(job_class, *args)
      @resque_jobs_to_enqueue_in_after_commit ||= []
      @resque_jobs_to_enqueue_in_after_commit << { :job_class => job_class, :args => args }
    end

    def enqueue_resque_jobs
      return if @resque_jobs_to_enqueue_in_after_commit.blank?
      resque_jobs_to_enqueue_in_after_commit.dup.each do |job|
        Resque.enqueue(job[:job_class], *job[:args])
        @resque_jobs_to_enqueue_in_after_commit.delete(job)
      end
    end

  end

end