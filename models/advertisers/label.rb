module Advertisers::Label

  def generate_label_from_name
    if label.blank? && name.present?
      self.label = generate_unique_label
    end
  end

  def generate_label_from_name!
    generate_label_from_name
    save
  end

  private

  def generate_unique_label
    new_label = name.gsub("'", "").parameterize.to_s
    if publisher
      max_label = last_label_for_matching_advertisers(new_label)
      if max_label
        i = (max_label.match(/-(\d+)$/).try(:[], 1) || 1).to_i
        new_label = "#{new_label}-#{i + 1}"
      end
    end
    new_label
  end

  def last_label_for_matching_advertisers(match)
    others = publisher.advertisers.reject{|a| a.id == id}
    matching = others.select{|a| a.label =~ /\A#{Regexp.escape match}/}
    last_label = matching.sort_by(&:id).last.try(:label)
  end

end