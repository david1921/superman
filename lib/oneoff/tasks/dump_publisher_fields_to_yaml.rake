namespace :oneoff do

  FIELDS_TO_DUMP = %w(
    brand_name daily_deal_brand_name brand_headline brand_txt_header
    brand_twitter_prefix daily_deal_sharing_message_prefix
    daily_deal_twitter_message_prefix gift_certificate_disclaimer
    daily_deal_email_signature how_it_works_source
    daily_deal_universal_terms_source
  )

  FIELD_MAP = {
    'how_it_works_source' => 'how_it_works',
    'daily_deal_universal_terms_source' => 'daily_deal_universal_terms'
  }

  desc "dump translatable publisher fields to locale YAML files"
  task :dump_publisher_fields_to_locale_files do
    require 'fileutils'

    PublishingGroup.all(:conditions => 'label IS NOT NULL AND label <> ""').each do |publishing_group|
      common, different = publishing_group.publishers.inject([{}, Set.new]) do |result, publisher|
        common, different = result

        publisher_fields = fields_to_dump_for_publisher(publisher)

        if common.blank?
          common = publisher_fields
        else
          different.merge(publisher_fields.diff(common).keys)

          different.each do |key|
            common.delete(key)
          end
        end

        [common, different]
      end

      different = different.to_a

      if different.present?
        different.each do |field|
          most_common = publishing_group.publishers.map(&:"#{field}").group_by(&:to_s).values.sort_by(&:count).reverse

          if most_common.second && most_common.first.count > most_common.second.count
            common[field.to_s] = most_common.first.first
          end
        end

        publishing_group.publishers.each do |publisher|
          fields = {}
          FIELDS_TO_DUMP.each do |field|
            value = publisher.send(field)
            fields[field] = value if value.present? && value != common[field]
          end

          write_themed_locale_file(publisher.label, fields)
        end
      end

      write_themed_locale_file(publishing_group.label, common)
    end

    PublishingGroup.all(:conditions => 'label IS NULL OR label = ""').each do |publishing_group|
      publishing_group.publishers.each{|publisher| write_publisher_fields(publisher) }
    end

    Publisher.all(:conditions => 'publishing_group_id IS NULL').each{|publisher| write_publisher_fields(publisher)}
  end

  def field_name(name)
    (FIELD_MAP[name] || name).to_s
  end

  def write_publisher_fields(publisher)
    write_themed_locale_file(publisher.label, fields_to_dump_for_publisher(publisher))
  end

  def fields_to_dump_for_publisher(publisher, dump_fields = FIELDS_TO_DUMP)
    fields = {}
    dump_fields.each do |field|
      value = publisher.send(field)
      fields[field] = value if value.present?
    end
    fields
  end

  def remap_fields(fields)
    new_fields = {}
    fields.each_pair do |key, value|
      new_fields[field_name(key)] = value
    end
    new_fields
  end

  def write_themed_locale_file(label, contents)
    locale_dir = File.expand_path("config/locales/themes/#{label}", RAILS_ROOT)
    locale_file = File.join(locale_dir, 'en.yml')

    old_contents = YAML.load(File.read(locale_file)) if File.exists?(locale_file)

    contents = contents.delete_if{ |key, value| value.blank? }
    if contents.size > 0
      contents = remap_fields(contents)
      contents = {'en' => {label => contents}}
      contents = old_contents.merge(contents) if old_contents

      FileUtils.mkdir_p(locale_dir)
      puts "Writing #{locale_file}"
      File.open(locale_file, 'w') do |f|
        f.write(contents.to_yaml)
      end
    end
  end

end
