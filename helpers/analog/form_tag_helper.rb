module Analog
  module FormTagHelper
    def error_div(error_message)
      %Q{
<div class="row">
  <div class="error_message">#{error_message}</div>
</div>}.html_safe
    end

    def text_field_tag_div(name, method, text = nil, text_field_options = {})
      label_options = text_field_options.delete(:label) || {}
      help = text_field_options.delete(:help)
      required = text_field_options.delete(:required)
      %Q{
<div class="row">
  <div class="label">#{label_tag(name, text, label_options)}</div>
  <div class="input">#{text_field_tag(name, method, text_field_options)}</div>
  <div class="help">#{"Required" if required}#{help}</div>
</div>}.html_safe
    end
  end
end
