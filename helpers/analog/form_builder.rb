# Our custom FormBuilder just delegates to Rails' FormBuilder which strips tags
module Analog
  class FormBuilder < ActionView::Helpers::FormBuilder
    def label(method, text = nil, options = {}, append_colon = false)
      text = label_from_method(method).to_s unless text.present?
      text << ":" unless text.ends_with?(":") || !append_colon
      @template.label(@object_name, method, text || label_from_method(method), objectify_options(options)).html_safe
    end

    def label_from_method(method_name)
      return if method_name.nil?
      content = method_name.to_s.titleize
      return content if object.nil?
      if @object.class.respond_to?(:human_attribute_name)
        content = @object.class.human_attribute_name(method_name)
      end
      content = content.to_s
    end

    def check_box_div(method, text = nil, check_box_options = {})
      type = check_box_options.delete(:type) || ""
      if type == :label_left
        %Q{
<div class="row">
  <div class="label">#{label(method, text)}</div>
  <div class="check_box">
    #{check_box(method, check_box_options)}
  </div>
</div>}.html_safe
      else
        %Q{
<div class="row check_box">
  #{check_box(method, check_box_options)}
  #{label(method, text || method.to_s.titleize)}
</div>}.html_safe
      end
    end

    def radio_button_div(method, tag_value, text = nil, radio_button_options = {})
      label_options = radio_button_options.delete(:label) || {}
      %Q{
<div class="row radio_button">
  #{radio_button(method, tag_value, radio_button_options)}
  #{label(method, text || method.to_s.titleize, label_options)}
</div>}.html_safe
    end

    def select_div(method, choices, options = {}, html_options = {})
      %Q{
<div class="row">
  <div class="label">#{label(method, options[:label_text], html_options, true)}</div>
  <div class="input">#{select(method, choices, options, html_options)}</div>
</div>
}.html_safe
    end

    def password_field_div(method, text = nil, password_field_options = {})
      label_options = password_field_options.delete(:label) || {}
      help = password_field_options.delete(:help)
      required = password_field_options.delete(:required)
      %Q{
<div class="row">
  <div class="label">#{label(method, text, label_options, true)}</div>
  <div class="input">#{password_field(method, password_field_options)}</div>
  <div class="help">#{"Required" if required}#{help}</div>
</div>}.html_safe
    end

    def text_field_div(method, text = nil, text_field_options = {})
      label_options = text_field_options.delete(:label) || {}
      help = text_field_options.delete(:help)
      required = text_field_options.delete(:required)
      %Q{
<div class="row">
  <div class="label">#{label(method, text, label_options, true)}</div>
  <div class="input">#{text_field(method, text_field_options)}</div>
  <div class="help">#{"Required" if required}#{help}</div>
</div>}.html_safe
    end

    def text_area_div(method, text = nil, text_area_options = {})
      label_options = text_area_options.delete(:label) || {}
      help = text_area_options.delete(:help)
      required = text_area_options.delete(:required)
      %Q{
<div class="row">
  <div class="label">#{label(method, text, label_options)}</div>
  <div class="input">#{text_area(method, text_area_options)}</div>
  <div class="help">#{"Required" if required}#{help}</div>
</div>}.html_safe
    end

    def file_field_div(method, text=nil, file_field_options={})
      label_options = file_field_options.delete(:label) || {}
      help = file_field_options.delete(:help)
      required = file_field_options.delete(:required)
      %Q{
<div class="row">
  <div class="label">#{label(method, text, label_options)}</div>
  <div class="input">#{file_field(method, file_field_options)}</div>
  <div class="help">#{"Required" if required}#{help}</div>
</div>}.html_safe
    end

    def text_div(method, label)
      %Q{
<div class="row">
  <div class="label">#{label(method, label)}</div>
  <div class="input">#{@object.send(method)}</div>
</div>}.html_safe
    end

    def category_selection_div(collection_method, categories, label, options)
      method = collection_method.to_s.singularize + '_ids'

      label_options = options.delete(:label) || {}
      help = options.delete(:help)
      required = options.delete(:required)
      subcategory_url = options.delete(:subcategory_url)
      assigned_categories = @object.send(collection_method).map
      assigned_categories.sort!{|a, b| a.full_name.gsub(": ", "") <=> b.full_name.gsub(": ", "")}
      added_categories = assigned_categories.map do |category|
        %Q{
<li>
  <a href="javascript:;" title="Remove">x</a>
  <span>#{category.full_name}</span>
  <input type="hidden" name="#{@object_name}[#{method}][]" value="#{category.id}" />
  <div class="clear"></div>
</li>}
      end

      category_options = categories.map do |category|
        %Q{<option value="#{category.id}">#{category.name}</option>}
      end

      category_select_id = "#{method}_categories"
      subcategory_select_id = "#{method}_subcategories"
      subcategory_wrapper_id = "#{method}_subcategory_wrapper"
      add_button_id = "#{method}_add"
      list_id = "#{method}_list"

      %Q|
<div class="row">
  <div class="label"><label for="#{category_select_id}">#{label}:</label></div>
  <div class="input">
    <select id="#{category_select_id}" autocomplete="off">
      <option value="0">&lt;Please Select&gt;</option>
      #{category_options.join('')}
    </select>
    :
    <span id="#{subcategory_wrapper_id}"></span>
    <input type="button" id="#{add_button_id}" style="display:none" value="Add" />
    <ul id="#{list_id}" class="category_list">#{added_categories}</ul>
  </div>
  <div class="help">#{"Required" if required}#{help}</div>
</div>
<script type="text/javascript">
  setupCategorySelection('#{@object_name}', '#{method}', '#{subcategory_url}');
</script>
|.html_safe
    end
  end
end
