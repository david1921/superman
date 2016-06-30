class HydraClassCommentDetector
  # Detect if file is missing a Hydra class comment
  def self.detect(glob_path)
    Dir.glob(glob_path).each do |file|
      File.open(file) do |f|
        begin
          klass_def = nil
          i = 0
          while line = f.readline and i < 30 do
            klass_def = line =~ /\< \w+\:\:TestCase/ or line =~ /< \w+\:\:IntegrationTest/
            break if line =~ %r{^\# hydra class}
            if line =~ /^module/ and !klass_def
              puts "Missing Hydra class comment:"
              puts file
              break
            end
            i += 1
          end
        rescue EOFError 
        end
      end
    end
  end
end
