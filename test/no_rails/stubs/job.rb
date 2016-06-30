class Job

  def self.run!(*ignored)
    yield
  end

end
