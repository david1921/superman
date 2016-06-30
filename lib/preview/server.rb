module Preview
  
  DESIGNERS = {
    :Thryn => "thryn",
    :greendezine => "stng",
    :dshapira => "daniel",
    :mwitek => "matt",
    :brookerman => "jeff",
    :jontanner => "jon",
    :jmgarrison => 'jesse',
    :wilsonrector => 'wilson',
    :austin => 'austin',
    :sam => 'sam'
  }
  DESIGNER_DIR_PREFIX = "/var/lib/cijoe"
  
  RUBY_BIN_DIR = "/usr/local/rvm/gems/ree-1.8.7-2010.02/bin"
  
  module Server
    
    class << self
      
      def update_code_and_restart!(options)
        designer_name = options[:designer_name] || get_designer_name_from_git_config!
        branch_name = options[:branch_name]
        dry_run = ENV["DRY_RUN"].present?
      
        raise ArgumentError, "missing required argument designer_name" unless designer_name.present?
        raise ArgumentError, "expected designer name to be one of: #{designer_names.join(', ')}. got: #{designer_name}." unless designer_names.include?(designer_name)
      
        unless branch_name.present?
          branch_name = get_current_branch_name
        end
      
        designer_server = "#{designer_name}.analoganalytics.net"
        puts "Checking out master and pulling on #{designer_server}..."
        checkout_master_and_pull(designer_name, dry_run)
        puts "Switching to branch #{branch_name} and pulling..."
        checkout_and_pull_requested_branch_into_designer_dir(branch_name, designer_name, dry_run)
        run_bundle_install! designer_name, dry_run
        restart_preview_server(designer_name, dry_run)
        puts "Updated #{designer_server} successfully."
      end
    
      private
    
      def get_designer_name_from_git_config!
        github_username = `git config --list | grep github.user`.strip.split("=")[1] rescue nil
        unless github_username.present? && DESIGNERS[github_username.to_sym].present?
          raise "unable to determine designer name (try setting it explicitly with, e.g., DESIGNER=stng. valid names: #{designer_names.join(', ')})"
        end
        DESIGNERS[github_username.to_sym]
      end
      
      def designer_names
        DESIGNERS.values
      end

      def get_current_branch_name
        `git branch`.split("\n").grep(/^\*/).first[2..-1]
      end
      
      def checkout_and_pull_requested_branch_into_designer_dir(branch_name, designer_name, dry_run = false)
        executed_remotely("git checkout #{branch_name} && git pull origin #{branch_name}", designer_name, dry_run)
      end
      
      def checkout_master_and_pull(designer_name, dry_run = false)
        executed_remotely("git reset --hard && git clean -fd && git checkout master && git pull", designer_name, dry_run)
      end

      def run_bundle_install! designer_name, dry_run
        bundled_gems_path = "#{DESIGNER_DIR_PREFIX}/shared/bundle"
        executed_remotely "mkdir -p #{bundled_gems_path}", designer_name, dry_run
        
        bundle_cmd  = "RAILS_ENV=nightly #{RUBY_BIN_DIR}/bundle install --deployment --path=#{bundled_gems_path}"
        executed_remotely bundle_cmd, designer_name, dry_run
      end
      
      def restart_preview_server(designer_name, dry_run = false)
        executed_remotely "DESIGNER_NAME=#{designer_name} RAILS_ENV=nightly #{RUBY_BIN_DIR}/rake preview:update", designer_name, dry_run
      end
      
      def executed_remotely cmd, designer_name, dry_run=false
        full_cmd = %Q{ssh app@app30.analoganalytics.com "cd #{DESIGNER_DIR_PREFIX}/#{designer_name} && #{cmd}"}
        if dry_run
          puts "**DRY_RUN: #{full_cmd}"
        else
          puts full_cmd
          %x{#{full_cmd}}
        end
      end
      
    end
    
  end

end
