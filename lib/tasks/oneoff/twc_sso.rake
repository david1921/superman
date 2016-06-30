namespace :oneoff do
  namespace :twc_sso do
    desc "Clean up invalid consumers and combine duplicate consumers for twc SSO prep"
    task :clean_invalid_consumers_and_combine_in_publishing_group => :environment do
      dry_run = true
      PublishingGroup.transaction do 
        ['ryan.pfeiffer', 'marianne.lontoc', 'glenn.meyer', 'derek.speranza'].each do |name|
          cons = Consumer.find(:all, :conditions => "email LIKE '%#{name}%'")
          cons.each do |c|
            c.sweepstake_entries.delete_all
            c.save
          end
        end
        pg = PublishingGroup.find_by_label('rr')
        pg.combine_duplicate_consumers! 
        raise ActiveRecord::Rollback if dry_run
      end
    end
    # usage: rake oneoff:twc_sso:clean_invalid_consumers_in_publishing_group
  end
end