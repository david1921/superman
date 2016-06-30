class DelimitedFile
  def self.open(file_path, delimiter)
    File.open(file_path, "w") do |file|
      delimited_file = DelimitedFile.new(file, delimiter)
      yield delimited_file if block_given?
    end
  end

  def initialize(file, delimiter=",")
    @file      = file
    @delimiter = delimiter
  end

  def <<(line)
    line = line.join(@delimiter)
    @file << line
    @file << "\n"
  end
end
