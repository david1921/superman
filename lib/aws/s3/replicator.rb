module AWS
  module S3
    module Replicator
      class << self
        def sync_latest_production_assets!
          unless valid_target_provided?
            raise ArgumentError, "TARGET must be one of 'nightly' or 'staging'"
          end

          unless valid_model_class_provided?
            raise ArgumentError, "CLASS argument is required and must one of: #{allowed_model_classes_with_attachments.join(', ')}"
          end

          target_env = ENV["TARGET"]
          establish_connection!

          klass = model_class_with_attachments

          attachment_definitions = klass.attachment_definitions
          recently_added_or_updated_instances = klass.find(
            :all, :conditions => ["created_at >= ? OR updated_at >= ?", 7.days.ago, 7.days.ago])
          recently_added_or_updated_instances.each do |m|
            verbose "*** syncing #{m.class} #{m.id}"
            attachment_definitions.each_pair do |name, definition|
              next unless definition[:bucket]
              
              bucket = definition[:bucket]
              s3_prod_key_prefix = "production/#{m.id}" 
              s3_target_key_prefix = "#{target_env}/#{m.id}" 
              attachment = m.send(name)
              verbose_prefix = "#{m.class} (#{m.id}) / #{bucket}:"
              
              attachment.styles.keys.each do |style|
                if style == :full_size
                  s3_prod_key = "#{s3_prod_key_prefix}/original.jpg"
                  s3_target_key = "#{s3_target_key_prefix}/original.jpg"
                else
                  s3_prod_key = "#{s3_prod_key_prefix}/#{style}.png"
                  s3_target_key = "#{s3_target_key_prefix}/#{style}.png"
                end
                s3_prod_object_value = s3_prod_object_policy = nil
                
                if AWS::S3::S3Object.exists?(s3_prod_key, bucket)
                  print "#{verbose_prefix}: FETCHING #{s3_prod_key}" if verbose?
                  s3_prod_object_value = AWS::S3::S3Object.value(s3_prod_key, bucket)
                  s3_prod_object_policy = AWS::S3::S3Object.acl(s3_prod_key, bucket)
                  print " (#{(s3_prod_object_value.size / 1000.0).round(1)} KB)" if s3_prod_object_value && verbose?
                  print "\n" if verbose?
                end

                unless s3_prod_object_value
                  verbose "#{verbose_prefix}: SKIPPING #{s3_prod_key} (Not Found)"
                  next
                end
                
                if AWS::S3::S3Object.exists?(s3_target_key, bucket)
                  verbose "#{verbose_prefix}: *NOT* COPYING TO #{s3_target_key} (Already Exists)"
                  next
                end

                if verbose?
                  print "#{verbose_prefix}: COPYING TO #{s3_target_key}"
                  print " (** dry run **)" if dry_run?
                  print "\n"
                end
                
                unless dry_run?
                  AWS::S3::S3Object.store(s3_target_key, s3_prod_object_value, bucket)
                  AWS::S3::S3Object.acl(s3_target_key, bucket, s3_prod_object_policy)
                end
              end
            end
          end
        end
      
        def model_class_with_attachments
          ENV["CLASS"].constantize
        end
        
        def dry_run?
          @dry_run ||= ENV['DRY_RUN'].present?
        end
        
        def verbose?
          @verbose ||= ENV['VERBOSE'].present?
        end
        
        def verbose(msg)
          puts msg if verbose?
        end
        
        def establish_connection!
          config = YAML.load_file(File.expand_path("#{Rails.root}/config/paperclip_s3.yml", Rails.root))
          AWS::S3::Base.establish_connection!(
            :access_key_id     => config["access_key_id"],
            :secret_access_key => config["secret_access_key"]
          )
        end        
        
        private
        
        def valid_model_class_provided?
          ENV["CLASS"].present? && allowed_model_classes_with_attachments.include?(ENV["CLASS"])
        end
        
        def valid_target_provided?
          ENV["TARGET"].present? && %w(nightly staging).include?(ENV["TARGET"])
        end
        
        def allowed_model_classes_with_attachments
          [Advertiser, DailyDeal, GiftCertificate, Offer, Publisher].map(&:name)
        end
      end
    end
  end
end