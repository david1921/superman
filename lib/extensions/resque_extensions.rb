module Resque

  extend self

  alias_method :original_enqueue, :enqueue

  def enqueue(klass, *args)
    if should_raise_enqueuing_exceptions?
      original_enqueue(klass, *args)
    else
      Exceptional.rescue { original_enqueue(klass, *args) }
    end
  end

  # In production, we don't want to raise an exception when enqueuing jobs
  # because we don't want the user to see the exception, but we *do* want
  # to see these exceptions in Exceptional.
  def should_raise_enqueuing_exceptions?
    Resque.inline?
  end

end
