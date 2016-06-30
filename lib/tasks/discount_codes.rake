namespace :discount_codes do
  CHARSET = %w{ 2 3 4 6 7 9 A C D E F G H J K L M N P Q R T V W X Y Z}
  desc "Create discount codes for PUBLISHER_LABEL"
  task :generate_codes => :environment do
    task_ts = Time.now.to_s(:db)
    number_to_create = (ENV['COUNT'].present?) ? ENV['COUNT'].to_i : 0
    amount = (ENV['AMOUNT'].present?) ? ENV['AMOUNT'].to_i : 0
    first_usable_at = (ENV['USABLE_AT'].present?) ? ENV['USABLE_AT'] : task_ts
    last_usable_at = (ENV['USABLE_UNTIL'].present?) ? ENV['USABLE_UNTIL'] : 1.year.from_now.to_s(:db)
    usable_at_checkout = (ENV['USABLE_AT_CHECKOUT'].present?) ? ENV['USABLE_AT_CHECKOUT'] : 1
    usable_only_once = (ENV['USABLE_ONCE'].present?) ? ENV['USABLE_ONCE'] : true
    
  
    Publisher.transaction do
      discounts = 0
      number_to_create.times do
        begin
          uuid = UUIDTools::UUID.random_create.to_s
          Discount.connection.insert("INSERT INTO `discounts`
          (`created_at`, `code`, `quantity`, `uuid`, `updated_at`, `deleted_at`,
          `amount`, `first_usable_at`, `usable_at_checkout`,`lock_version`, `type`,
          `last_usable_at`, `publisher_id`, `usable_only_once`)
          VALUES('#{task_ts}', '#{code}', NULL, '#{uuid}',
          '#{task_ts}', NULL, #{amount.to_f}, '#{first_usable_at}', #{usable_at_checkout}, 0, NULL, '#{last_usable_at}', #{publisher.id}, #{usable_only_once})")
          discounts += 1
          if discounts % 10000 == 0
            puts discounts
          end
        rescue => e
          puts e
        end
      end
      puts "#{discounts} Discounts created"
    end #/transaction
  end #/task
end

def generate_codes(number=0, prefix=nil)
  used = Set.new
  number.times do |num|
    begin
      code = Array.new(6) { CHARSET.rand }.join
    end while used.member?(code)
    puts "#{prefix}#{code}"
    used << code
  end
end

# if File.exists?("#{Rails.root}/tmp/#{publisher.label}.csv")
# puts "Reading: " + publisher.label
# File.readlines("#{Rails.root}/tmp/#{publisher.label}.csv").map(&:strip).each do |code|
