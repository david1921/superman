module Liquid
  class ExtendedLocalFileSystem < LocalFileSystem

    def template_exists?(template_path)
      File.exists? expand_path(template_path)
    end

    def full_path(template_path)
      raise FileSystemError, "Illegal template name '#{template_path}'" unless template_path =~ /^[^.\/][a-zA-Z0-9_\/-]+(\.[a-zA-Z\-]+)?$/

      full_path = expand_path(template_path)
      
      raise FileSystemError, "Illegal template path '#{File.expand_path(full_path)}'" unless File.expand_path(full_path) =~ /^#{File.expand_path(root)}/
      
      full_path
    end

    private

    def expand_path(template_path)
      if template_path.include?('/')
        File.join(root, File.dirname(template_path), "_#{File.basename(template_path)}.html.liquid")
      else
        File.join(root, "_#{template_path}.html.liquid")
      end
    end
    
  end
end
