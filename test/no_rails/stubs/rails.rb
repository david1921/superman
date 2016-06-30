module Rails
  class Environment
    def production?
      false
    end
    
    def test?
      true
    end
  end

  # Should use Mocha to stub this
  class FakeLogger
    def info(msg)
      true
    end
  end

  def self.env
    Environment.new
  end

  def self.logger
    @logger ||= FakeLogger.new
  end
  
  def self.root
    File.expand_path(File.dirname(__FILE__) + "/../../../")
  end
end
