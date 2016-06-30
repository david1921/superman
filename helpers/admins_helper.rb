module AdminsHelper
  
  def disable_full_admin_setting?
    current_user.has_restricted_admin_privileges?
  end
  
  def manageable_publishers_list(user = nil)
    companies = user.try(:companies)
    
    pubs_list = '<ul class="manageable-things" id="manageable-publishers-list">'
    
    companies.select { |c| c.is_a?(Publisher) }.each do |c|
      pubs_list << %Q{<li><a class="delete" href="#">[x]</a> #{c.name}<input type="hidden" name="manageable_publisher_ids[]" value="#{c.id.to_s}" /></li>}
    end if companies.present?
    
    pubs_list << "</ul>"
    pubs_list.html_safe
  end
  
  def manageable_publishing_groups_list(user = nil)
    companies = user.try(:companies)
    pub_groups_list = '<ul class="manageable-things" id="manageable-publishing-groups-list">'

    companies.select { |c| c.is_a?(PublishingGroup) }.each do |c|
      pub_groups_list << %Q{<li><a class="delete" href="#">[x]</a> #{c.name}<input type="hidden" name="manageable_publishing_group_ids[]" value="#{c.id}" /></li>}
    end if companies.present?
    
    pub_groups_list << '</ul>'
    pub_groups_list.html_safe
  end
  
  def manageable_publishers_select
    publisher_options = Publisher.manageable_by(current_user).all(:select => "id, name", :order => :name).map do |p|
      "<option value='#{p.id}'>#{p.name}</option>"
    end
    select_tag("manageable-publishers", publisher_options.join.html_safe)
  end
  
  def manageable_publishing_groups_select
    pub_group_options = PublishingGroup.manageable_by(current_user).all(:select => "id, name", :order => :name).map do |pg|
      "<option value='#{pg.id.to_s}'>#{pg.name}</option>"
    end
    select_tag("manageable-publishing-groups", pub_group_options.join.html_safe)
  end
  
end